require_relative '../hole_punching'

PORT=43596
class HolePunching::Stun
  @@peers = []
  def self.join(*args)
    args = args.first
    @ip = args[:ip]
    @port = args[:port]
    @id = Digest::SHA1.hexdigest(Time.now.to_f.to_s + @ip + @port.to_s)

    if @@peers.select{|peer| peer[:ip] == @ip and peer[:port] == @port}.size == 0
      puts "[JOIN] #{@ip}:#{@port}"
      @@peers << {:id => @id, :ip => @ip, :port => @port}
    end
    
    ['your_info', {:id => @id}]
  end

  def self.not_own_peers(id)
    ['peers_info', @@peers.select{|peer| peer[:id] != id}]
  end

  def self.rcall(*args)
    args = args.first
    func = args[:func]
    ip = args[:ip]
    port = args[:port]
    id = args[:id]
    case func
      when 'join'
        self.join(ip: ip, port: port)
      when 'peers_info'
        self.not_own_peers(id)
    end
  end

  def self.recv
    Socket.udp_server_sockets(PORT) do |sockets|
      loop do
        readable, _, _ = IO.select(sockets)
        Socket.udp_server_recv(readable) do |msg, msg_src|
          ip, port = msg_src.remote_address.ip_unpack

          begin
            body = MessagePack.unpack(msg)
            func = body['func']
            id = body['id']
          rescue => e
            puts "[ERROR] #{e.message}"
          end

          reply_func, reply_body = self.rcall(func: func, id: id, ip: ip, port: port)
          msg_src.reply ({:func => reply_func, :body => reply_body}.to_msgpack)
        end
      end
    end
  end
end
