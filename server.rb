require 'socket'
require 'rubycards'
include RubyCards
require 'pry'

class Card
  def value
    [self.to_i, 10].min
  end
end

class Hand
  def sum
    self.cards.reduce(0) {|m,c| m += c.value }
  end
end

wins = 0
games = 0

port = 8081
socketServer = TCPServer.open(port)
puts "starting socket server on port #{port}"


loop do
  Thread.new(socketServer.accept) do |connection|
    puts "starting a game"

    begin
      games += 1
      deck = Deck.new
      srand Time.now.to_i
      rand(50).times {deck.cards.shuffle!}

      house_hand = Hand.new
      house_hand.draw(deck, 2)
      game_over = false

      player_hand = Hand.new
      player_hand.draw(deck, 2)

      connection.puts "the house's hand, win ratio: #{wins/games}"
      connection.puts house_hand[1]
      connection.puts "your hand: #{player_hand.sum}"
      connection.puts player_hand

      while player_hand.sum <= 21
        action = connection.gets.strip

        if action =~ /h/
          player_hand.draw(deck, 1)
          connection.puts "your hand: #{player_hand.sum}"
          connection.puts player_hand

          if player_hand.sum == 21
            connection.puts "you win!"
            connection.close
            game_over = true
          elsif player_hand.sum > 21
            connection.puts "you lose"
            connection.close
            wins += 1
            game_over = true
          end
        elsif action =~ /s/
          break
        end
      end

      if player_hand.sum > 21 and game_over
        connection.puts "you lose!"
        connection.close
        wins += 1
      end

      connection.puts "house hand: #{house_hand.sum}"
      connection.puts house_hand

      while house_hand.sum < 21
        if house_hand.sum > 17
          break
        else
          house_hand.draw(deck, 1)
        end
        connection.puts "house plays: #{house_hand.sum}"
        connection.puts house_hand
      end

      if house_hand.sum <= 21 and player_hand.sum < house_hand.sum
        connection.puts "you lose!"
        wins += 1
      elsif house_hand.sum > 21
        connection.puts "you win!"
      elsif house_hand.sum > player_hand.sum and house_hand.sum <= 21
        connection.puts "you lose!"
        wins += 1
      elsif house_hand.sum < player_hand.sum and house_hand.sum <= 21
        connection.puts "you win!"
      elsif house_hand.sum == player_hand.sum
        connection.puts "tie!"
      end

      connection.close
    rescue Exception => e
      puts "#{ e } (#{ e.class })"
    ensure
      players.delete handle
      connection.close
      puts "connection closed"
    end
  end
end
