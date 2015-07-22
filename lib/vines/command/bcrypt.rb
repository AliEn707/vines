# encoding: UTF-8

module Vines
  module Command
    class Bcrypt
      def run(opts)
	require opts[:config]
        raise 'vines bcrypt <clear text>' unless opts[:args].size == 1
        puts BCrypt::Password.create("#{opts[:args].first}#{Vines::Config.instance.pepper}", cost: 10)
      end
    end
  end
end