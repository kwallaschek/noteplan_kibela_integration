module MacCommentAbility
  def self.osascript(script)
    system 'osascript', *script.split(/\n/).map { |line| ['-e', line] }.flatten
  end

  def self.read_comment(path)
    osascript <<-END
      do shell script "echo  > #{ENV["TMPDIR"]}kibela_tmp_id.txt"
      tell application "Finder"
        set s to (POSIX file "#{path}" as alias)
        set c to comment of s
      end tell
      do shell script "touch #{ENV["TMPDIR"]}kibela_tmp_id.txt"
      do shell script "chmod +x #{ENV["TMPDIR"]}kibela_tmp_id.txt"
      set command to "echo " & c & " > #{ENV["TMPDIR"]}kibela_tmp_id.txt" 
      do shell script command
    END

    tmp_file = File.open("#{ENV["TMPDIR"]}kibela_tmp_id.txt")
    id = tmp_file.read
  end

  def self.write_comment(path, comment)
    osascript <<-END
      tell application "Finder" to set comment of (POSIX file "#{path}" as alias) to "#{comment}" as Unicode text
          return
    END
  end

  def self.read_attachment_comment(path)
    osascript <<-END
      do shell script "echo  > #{ENV["TMPDIR"]}kibela_tmp_path.txt"
      tell application "Finder"
        set s to (POSIX file "#{path}" as alias)
        set c to comment of s
      end tell
      do shell script "touch #{ENV["TMPDIR"]}kibela_tmp_path.txt"
      do shell script "chmod +x #{ENV["TMPDIR"]}kibela_tmp_path.txt"
      set command to "echo " & c & " > #{ENV["TMPDIR"]}kibela_tmp_path.txt" 
      do shell script command
    END

    tmp_file = File.open("#{ENV["TMPDIR"]}kibela_tmp_path.txt")
    id = tmp_file.read
  end

  def self.write_attachment_comment(path, comment)
    osascript <<-END
      tell application "Finder" to set comment of (POSIX file "#{path}" as alias) to "#{comment}" as Unicode text
          return
    END
  end

  def self.init
    osascript <<-END
      do shell script "touch #{ENV["TMPDIR"]}kibela_tmp_path.txt"
      do shell script "chmod +x #{ENV["TMPDIR"]}kibela_tmp_path.txt"
      do shell script "echo  > #{ENV["TMPDIR"]}kibela_tmp_path.txt"  

      do shell script "touch #{ENV["TMPDIR"]}kibela_tmp_id.txt"
      do shell script "chmod +x #{ENV["TMPDIR"]}kibela_tmp_id.txt"
      do shell script "echo  > #{ENV["TMPDIR"]}kibela_tmp_id.txt"
    END
  end
end
