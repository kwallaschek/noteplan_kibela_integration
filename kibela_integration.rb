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


def disect_path(file_path)
  path = file_path.gsub(NOTEPLAN_BASE_PATH, "")
  path = path.gsub("/#{File.basename(file_path)}", "")
end

def add_note(file_path)
  file = File.open(file_path)
  title = file.readline[2..-1]
  content = file.read
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
  path = disect_path(file_path)

  if file_kibela_id
    puts "Get Kibela status for #{file_kibela_id}"
    old_file = KibelaAPI::pull_note(file_kibela_id)

    puts "Update #{file_kibela_id} on Kibela"
    KibelaAPI::update_note_req(file_kibela_id, title, content, old_file, path)
  end
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

  listener.start
  sleep
end

listener