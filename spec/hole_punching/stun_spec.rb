require 'hole_punching/stun'
require 'digest/sha1'

describe HolePunching::Stun do
  describe :join do
    let(:ip) {"#{rand(255)}.#{rand(255)}.#{rand(255)}.#{rand(255)}" }
    let(:port) {rand(50000) + 1024}

    before do
      HolePunching::Stun.class_variable_set(:@@peers, [])
    end

    it "ハッシュで保存される" do
      HolePunching::Stun.join(ip: ip, port: port)
      expect(
        HolePunching::Stun.class_variable_get(:@@peers).first[:ip]
      ).to eq(ip)
      expect(
        HolePunching::Stun.class_variable_get(:@@peers).first[:port]
      ).to eq(port)
    end

    it "重複してjoinされない" do
      HolePunching::Stun.join(ip: ip, port: port)
      HolePunching::Stun.join(ip: ip, port: port)
      expect(
        HolePunching::Stun.class_variable_get(:@@peers).size
      ).to eq 1
    end

    it "40バイトが返る" do
      expect(
        HolePunching::Stun.join(ip: ip, port: port).size
      ).to eq 40
    end
  end

  describe :not_own_peers do
    before do
      HolePunching::Stun.class_variable_set(:@@peers, [])

      @hashs = []
      10.times.each do |i|
        ip = "#{rand(255)}.#{rand(255)}.#{rand(255)}.#{rand(255)}"
        port = rand(50000) + 1024
        id = HolePunching::Stun.join(ip: ip, port: port)
        @hashs << {id: id, ip: ip, port: port}
      end
    end

    it "特定のピア以外のHashがArrayで返る" do
      rand = rand(10)
      @arrs = []
      @hashs.each.with_index do |v, i|
        @arrs << v unless i == rand
      end
      expect( 
        HolePunching::Stun.not_own_peers(@hashs[rand][:id])
      ).to eq @arrs
    end
  end

  describe :rcall do
    let(:ip) {"#{rand(255)}.#{rand(255)}.#{rand(255)}.#{rand(255)}" }
    let(:port) {rand(50000) + 1024}

    context "funcが:joinのとき" do
      before do
        expect(HolePunching::Stun).to receive(:join).and_return(:join)
      end

      it "self.joinが呼ばれる" do
        expect(
          HolePunching::Stun.rcall(func: :join, ip: ip, port: port)
        ).to eq :join
      end
    end

    context "funcが:peers_infoのとき" do
      before do
        expect(HolePunching::Stun).to receive(:not_own_peers).and_return(:peers_info)
      end

      it "self.peers_infoが呼ばれる" do
        expect(
          HolePunching::Stun.rcall(func: :peers_info, ip: ip, port: port)
        ).to eq :peers_info
      end
    end
  end

  describe :recv do
    pending
  end
end
