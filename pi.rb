
require 'zip/zip'
Zip::ZipInputStream.open_buffer(StringIO.new(last_response.body)) do |io|
  while (entry = io.get_next_entry)
    puts "Contents of #{entry.name}: '#{io.read}'"
  end
end
