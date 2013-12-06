require_relative '../hole_punching'

STUN_SERVER="127.0.0.1"
STUN_PORT=43596
class HolePunching::Peer
  @@id = nil
  @@socket = Socket.udp_server_sockets(0)
  @@peers = []
  def self.join
    addr = Socket.sockaddr_in(STUN_PORT, STUN_SERVER)
    @@socket[0].sendmsg({:func => :join}.to_msgpack, 0, addr)
  end

  def self.rcall(*args)
    args = args.first
    func = args[:func]
    ip = args[:ip]
    port = args[:port]
    id = args[:id]
    payload = args[:payload]
    case func
      when 'your_info'
        self._id(payload['id'])
      when 'peers_info'
        self._peers_info(payload)
      when 'connect'
        self._connect
      when 'connect_reply'
        self._connect_reply
    end
  end

  def self._id(id)
    puts "[YOURID] #{id}"
    @@id = id
  end

  def self.peers_info
    addr = Socket.sockaddr_in(STUN_PORT, STUN_SERVER)
    @@socket[0].sendmsg({:func => :peers_info, :id => @@id}.to_msgpack, 0, addr)
  end

  def self._peers_info(peers)
    puts "[PEERS] RELOAD"
    @@peers = peers
  end

  def self.peers_connect
    Thread.new do
      loop do
        @@peers.each do |peer|
          addr = Socket.sockaddr_in(peer['port'], peer['ip'])
          @@socket[0].sendmsg({func: :connect, id: @@id}.to_msgpack, 0, addr)
        end
        sleep 15
      end
    end
  end

  def self._connect
    puts "[CONNECT]"
    ['connect_reply', {:id => @@id}]
  end

  def self._connect_reply
    puts "[CONNECT REPLY]"
  end

  def self.listen
    Thread.new do
      loop do
        readable, _, _ = IO.select(@@socket)
        Socket.udp_server_recv(readable) do |msg, msg_src|
          ip, port = msg_src.remote_address.ip_unpack

          begin
            body = MessagePack.unpack(msg)
            func = body['func']
            id = body['id']
          rescue => e
            puts "[ERROR] #{e.message}"
          end

          reply_func, reply_body = self.rcall(func: func, id: id, ip: ip, port: port, payload: body['body'])
          unless reply_func.nil?
            msg_src.reply ({:func => reply_func, :body => reply_body}.to_msgpack)
          end
        end
      end
    end
  end
end
