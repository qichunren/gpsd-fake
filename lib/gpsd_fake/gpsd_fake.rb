require 'socket'
require "gpsd_fake/version"

module GpsdFake
  class Error < StandardError; end
  
  class Server		
		def initialize(options = {})
			@data_file = options[:file]
			puts "data;#{@data_file}"
			@server = TCPServer.open(options[:port] || 2947) # Server would listen on port 3000
		end

		def run
			gpsd_data = File.readlines(@data_file)
			loop do
				Thread.start(@server.accept) do |client|
					puts "A client connected."
					hello_message = client.recvfrom(128)[0] # ?WATCH={"enable":true,"json":true};\n
    			puts "RECV:#{hello_message.inspect}"
    			if hello_message == "?WATCH={\"enable\":true,\"json\":true};\n"
			  		client.puts("{\"class\":\"VERSION\",\"release\":\"3.16\",\"rev\":\"3.16\",\"proto_major\":3,\"proto_minor\":11}\r\n")

			  		loop.with_index do |_, i|
			  			sleep 1
			  			time_str = Time.now.strftime("%Y-%m-%dT%H:%M:%S.%3NZ")

			  			data_line = gpsd_data[i].to_s.strip
			  			lon, lat = data_line.split(',').collect{|num| num.to_f }

			  			msg = "{\"class\":\"TPV\",\"device\":\"/dev/pts/4\",\"mode\":3,\"time\":\"#{time_str}\",\"ept\":0.005,\"lat\":#{lat},\"lon\":#{lon},\"alt\":1000,\"epx\":2.234,\"epy\":2.454,\"epv\":5.345,\"track\":136.5922537017672,\"speed\":16.666666666666668,\"climb\":0.000}\r\n"
			  			begin
			  				client.puts msg
			  			rescue Errno::EPIPE
			  				puts "Client disconnected."
			  				break
			  			end
			  		end
			  	end
  			end # end Thread.start
			  
			end # end loop
		end
  end	

end
