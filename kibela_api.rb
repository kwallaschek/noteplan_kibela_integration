require 'net/http'
require 'json'

module KibelaAPI
  def self.upload_attachment(file_path)
    puts "UPLOAD ATTACHMENT: "

    resp = req({
      query: <<~GRAPHQL,
        mutation($name: String!, $data: Blob!, $kind: AttachmentKind!, $groupIds: [ID!]!, $folders: [FolderInput!]) {
          uploadAttachment(input: { name: $name, data: $data, kind: GENERAL) {
            attachment {
              id,
              path
            }
          }
        }
      GRAPHQL
      variables: {
        name: file_name,
        data: file_as_blob,
      },
    })

    puts resp
    resp
  end

  def self.create_note(title, content, path)
    folderName = KIBELA_BASE_PATH + path

    puts "CREATE: #{title}"
    resp = req({
      query: <<~GRAPHQL,
        mutation($title: String!, $content: String!, $coediting: Boolean!, $groupIds: [ID!]!, $folders: [FolderInput!]) {
          createNote(input: { title: $title, content: $content, coediting: $coediting, groupIds: $groupIds, folders: $folders }) {
            note {
              url,
              id
            }
          }
        }
      GRAPHQL
      variables: {
        title: title,
        content: content,
        coediting: true,
        groupIds: GROUPID,
        folders: {groupId: GROUPID, folderName: folderName}
      },
    })

    puts resp
    resp
  end

  def self.pull_note(id)
    puts "PULL: #{id}"
    resp = req({
      query: <<~GRAPHQL,
        query($id: ID!) {
          note(id: $id) {
            title,
            content,
            folder {
              id,
              path
            }
          }
        }
      GRAPHQL
      variables: {
        id: id,
      },
    })

    puts resp
    resp
  end

  def self.update_note_req(id, title_new, content_new, old_file, path)
    folderName = KIBELA_BASE_PATH + path

    puts "UPDATE: #{id}"
    resp = req({
      query: <<~GRAPHQL,
        mutation($id: ID!, $newNote: NoteInput!, $baseNote: NoteInput!, $noteEditMemo: String) {
          updateNote(input: { id: $id, newNote: $newNote, baseNote: $baseNote, draft: false, noteEditMemo: $noteEditMemo}) {
            clientMutationId
            note {
              id
            }
          }
        }
      GRAPHQL
      variables: {
        id: id,
        newNote: {
          title: title_new,
          content: content_new,
          groupIds: GROUPID,
          coediting: true,
          folders: {groupId: GROUPID, folderName: folderName}
        },
        baseNote: {
          title: old_file[:data][:note][:title],
          content: old_file[:data][:note][:content],
          groupIds: GROUPID,
          coediting: true,
          folders: {groupId: GROUPID, folderName: old_file[:data][:note][:folder][:path].gsub("/notes/folder/","").gsub("?group_id=1","")}
        },
        noteEditMemo: "Automatically updated."
      },
    })

    puts resp
    resp
  end

  private

  def self.req(query)
    http = Net::HTTP.new("#{TEAM}.kibe.la", 443)
    http.use_ssl = true
    header = {
      "Authorization" => "Bearer #{TOKEN}",
      'Content-Type' => 'application/json',
      'User-Agent' => 'Simple Kibela Importer',
    }
    resp = http.request_post('/api/v1', JSON.generate(query), header)
    JSON.parse(resp.body, symbolize_names: true).tap do |content|
      raise content[:errors].inspect if content[:errors]
    end
  end
end