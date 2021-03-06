class Network
  def initialize blockchain, our_ip, node = nil
    @blockchain = blockchain
    @our_ip = our_ip
    @nodes = []

    self.add_node node, true if node
  end

  # if we are adding a node, because they send us a message, then we shouldn't
  # send them a connect message again. We should send connect messages for seed node
  def add_node node, seed_node = false
    return unless node

    puts "Connecting to node: #{node}"

    HTTParty.post "#{node}/connect", body: { ip: @our_ip } if seed_node
    @nodes << node
  end

  def broadcast_block block
    @nodes.each do |node|
      begin
        HTTParty.post "#{node}/relay", body: block.to_hash.to_json
      rescue
        #remove node?
      end
    end
  end

  def download_chain
    return if @nodes.empty?

    loop do
      index = @blockchain.last.index.to_i + 1
      response = HTTParty.get("#{@nodes.first}/blocks/#{index.to_s}")

      break if response.code != 200

      @blockchain << Block.from_json_str(response.body)
      # TODO use add_relayed_block instead
      puts "Downloaded #{@blockchain.last}"
    end

    puts "Finished downloading the chain"
  end
end
