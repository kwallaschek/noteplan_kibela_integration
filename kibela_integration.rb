require 'json'
require 'pathname'
require 'listen'
require_relative './mac_comment_ability'
require_relative './kibela_api'

TEAM = ""
TOKEN = ""
GROUPID = ""

NOTEPLAN_BASE_PATH = ""
KIBELA_BASE_PATH = ""

FILE_CHANGE_CHECKING_RATE = 360 # in seconds

MAGIC_KEYWORD_FOR_PULLING = "pull-kibela"

def handle_attachments(content, file_path)
  new_content = content.each_line.map do |line|
                  if line.include? "![image]"
                    path = line[9..-3]
                    base_name = File.basename(path)
                    full_file_path = "#{file_path[0..-5]}_attachments/#{base_name}"
                    kibela_path = MacCommentAbility::read_attachment_comment(full_file_path)
                    if kibela_path.size < 5
                      res = KibelaAPI::upload_attachment(full_file_path)
                      kibela_path = res[:data][:uploadAttachmentWithDataUrl][:attachment][:path]
                      MacCommentAbility::write_attachment_comment(full_file_path, kibela_path)
                    end
                    "<img title='写真' alt='写真' src='#{kibela_path}'>"
                  else
                    line
                  end
                end
  new_content.join('')
end


def disect_path(file_path)
  path = file_path.gsub(NOTEPLAN_BASE_PATH, "")
  path = path.gsub("/#{File.basename(file_path)}", "")
end

def add_note(file_path)
  file = File.open(file_path)
  title = file.readline[2..-1]
  content = file.read
  content = handle_attachments(content, file_path)
  path = disect_path(file_path)

  puts "Create the note \"#{title}\" on Kibela"
  res = KibelaAPI::create_note(title, content, path)

  file_kibela_id = res[:data][:createNote][:note][:id]
  puts "Write ID: #{file_kibela_id} to #{file_path}"
  MacCommentAbility::write_comment(file_path, file_kibela_id)
end

def update_note(file_path, file_kibela_id)
  file = File.open(file_path)
  title = file.readline[2..-1]
  content = file.read
  content = handle_attachments(content, file_path)
  path = disect_path(file_path)

  if file_kibela_id
    puts "Get Kibela status for #{file_kibela_id}"
    old_file = KibelaAPI::pull_note(file_kibela_id)

    puts "Update #{file_kibela_id} on Kibela"
    KibelaAPI::update_note_req(file_kibela_id, title, content, old_file, path)
  end
end

def has_to_be_pulled?(file_path)
  file = File.open(file_path)
  content = file.read
  content.each_line do |line|
    return true if line.include? MAGIC_KEYWORD_FOR_PULLING
  end
  false
end

def listener
  listener = Listen.to(NOTEPLAN_BASE_PATH+'/Notes', NOTEPLAN_BASE_PATH+'/Calendar', latency: FILE_CHANGE_CHECKING_RATE) do |modified, added, removed|
    puts(modified: modified, added: added, removed: removed)

    if added.size > 0 # Create Kibela Note 
      # Need to check if its added to the trash
      added.each do |file_path|
        add_note(file_path) 
      end
    end
    if modified.size > 0 # Update Kibela Note
      modified.each do |file_path|
        file_kibela_id = MacCommentAbility::read_comment(file_path).gsub("\n","")
        if file_kibela_id.size > 5
          update_note(file_path, file_kibela_id)
        else
          add_note(file_path)
        end
      end
    end
  end

  pulling_lister = Listen.to(NOTEPLAN_BASE_PATH+'/Notes', NOTEPLAN_BASE_PATH+'/Calendar') do |modified, added, removed|
    puts(modified: modified, added: added, removed: removed)

    if modified.size > 0 # Update Kibela Note
      modified.each do |file_path|
        file_kibela_id = MacCommentAbility::read_comment(file_path).gsub("\n","")
        if file_kibela_id.size > 5
          if has_to_be_pulled?(file_path)
            new_note = KibelaAPI::pull_note(file_kibela_id)
            File.open(file_path, "w") do |f|
              f.write "# #{new_note[:data][:note][:title]}"
              f.write new_note[:data][:note][:content]
            end
          end
        end
      end
    end
  end

  listener.start
  pulling_lister.start
  sleep
end

MacCommentAbility.init
listener
