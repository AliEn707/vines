require 'active_record'

module Vines
  class Storage
    class Sql < Storage
      register :sql
        
      class Message < ActiveRecord::Base
	belongs_to :user
	belongs_to :msg_dest, polymorphic: true
      end
      class Group < ActiveRecord::Base; end
      class User < ActiveRecord::Base
        has_many :messages, :dependent => :destroy
        has_many :income_messages, :as =>:msg_dest, :class_name => "Message", :dependent => :destroy
	has_many :friendships
	has_many :friends_out, :through => :friendships, :source => :friend
	has_many :inverse_friendships, :class_name => "Friendship", :foreign_key => "friend_id"
	has_many :friends_in, :through => :inverse_friendships, :source => :user
	has_one :profile
	def friends
#		user=User.arel_table
#		friends_out.where(user[:id].not_in(inverse_friendships.select(:user_id).map{|m| m.user_id}))
		friends_in.where(id: friendships.select(:friend_id))
	end
      end
      class Friendship < ActiveRecord::Base
	belongs_to :user, touch: true
	belongs_to :friend, :class_name => "User", touch: true
      end
      class User::Profile < ActiveRecord::Base
	belongs_to :user
	serialize :properties, JSON
      end
      # Wrap the method with ActiveRecord connection pool logic, so we properly
      # return connections to the pool when we're finished with them. This also
      # defers the original method by pushing it onto the EM thread pool because
      # ActiveRecord uses blocking IO.
      def self.with_connection(method, args={})
        deferrable = args.key?(:defer) ? args[:defer] : true
        old = instance_method(method)
        define_method method do |*args|
          ActiveRecord::Base.connection_pool.with_connection do
            old.bind(self).call(*args)
          end
        end
        defer(method) if deferrable
      end

      %w[adapter host port database username password pool prepared_statements].each do |name|
        define_method(name) do |*args|
          if args.first
            @config[name.to_sym] = args.first
          else
            @config[name.to_sym]
          end
        end
      end

      def initialize(&block)
        @config = {}
        instance_eval(&block)
        required = [:adapter, :database]
        required << [:host, :port] unless @config[:adapter] == 'sqlite3'
        required.flatten.each {|key| raise "Must provide #{key}" unless @config[key] }
        [:username, :password].each {|key| @config.delete(key) if empty?(@config[key]) }
        establish_connection
      end

      def find_user(jid)
        jid = JID.new(jid).bare.to_s
        return if jid.empty?
        xuser = user_by_jid(jid)
        return Vines::User.new(jid: jid).tap do |user|
	  profile=xuser.profile
          user.name, user.encrypted_password = profile.properties["NAME"],xuser.encrypted_password
          xuser.friends.each do |contact|
            groups = ["Friends"]
            user.roster << Vines::Contact.new(
              jid: contact.email,
              name: contact.profile.properties["NAME"],
              subscription: 'both',
              ask: "",
              groups: groups)
          end
        end if xuser
      end
      with_connection :find_user, defer: false

      def save_user(user)
=begin
		#add save user if need
        xuser = user_by_jid(user.jid) || Sql::User.new(jid: user.jid.bare.to_s)
        xuser.name = user.name
        xuser.encrypted_password = user.encrypted_password

        # remove deleted contacts from roster
        xuser.contacts.delete(xuser.contacts.select do |contact|
          !user.contact?(contact.jid)
        end)

        # update contacts
        xuser.contacts.each do |contact|
          fresh = user.contact(contact.jid)
          contact.update_attributes(
            name: fresh.name,
            ask: fresh.ask,
            subscription: fresh.subscription,
            groups: groups(fresh))
        end

        # add new contacts to roster
        jids = xuser.contacts.map {|c| c.jid }
        user.roster.select {|contact| !jids.include?(contact.jid.bare.to_s) }
          .each do |contact|
            xuser.contacts.build(
              user: xuser,
              jid: contact.jid.bare.to_s,
              name: contact.name,
              ask: contact.ask,
              subscription: contact.subscription,
              groups: groups(contact))
          end
        xuser.save
=end
      end
      with_connection :save_user

      def find_vcard(jid)
        jid = JID.new(jid).bare.to_s
        return if jid.empty?
        if xuser = user_by_jid(jid)
          Nokogiri::XML(xuser.profile.properties.build_vcard).root rescue nil
        end
      end
      with_connection :find_vcard, defer: false

      def save_vcard(jid, card)
        profile = user_by_jid(jid).profile
        if profile
          profile.prorerties = Hash.from_xml(card.to_xml).build_hash
          profile.save
        end
      end
      with_connection :save_vcard, defer: false

     def find_messages(jids)
		users={}
		Sql::User.select([:email,:id]).all.each{|u| users[u.id]=u}
		Message.where(msg_dest_id: Sql::User.where(email: jids).select(:id),msg_dest_type: "User").where("messages.created_at = messages.updated_at").map{|m| m.touch;{from: users[m.user_id].email ,to: users[m.msg_dest_id].email,text: m.data, created_at: m.created_at.to_i}}
     end
      with_connection :find_messages, defer: false

      def save_message(from, to, text)
	      return if from.empty? || to.empty? || text.empty?
	     Message.create(user_id: user_by_jid(from).id,
					msg_dest_id: Sql::User.where(email: to).first.id,
					msg_dest_type: "User",
					data: text)
      end
      with_connection :save_message, defer: false

      def find_fragment(jid, node)
       
      end
      with_connection :find_fragment, defer: false

      def save_fragment(jid, node)

      end
      with_connection :save_fragment, defer: false

      # Create the tables and indexes used by this storage engine.
      def create_schema(args={})
        args[:force] ||= false
=begin
        ActiveRecord::Schema.define do
          create_table :users, force: args[:force] do |t|
            t.string :jid,      limit: 512, null: false
            t.string :name,     limit: 256, null: true
            t.string :encrypted_password, limit: 256, null: true
            t.text   :vcard,    null: true
          end
          add_index :users, :jid, unique: true
        end
=end
      end
      with_connection :create_schema, defer: false

      private

      def establish_connection
        ActiveRecord::Base.logger = Vines::Log::log#ogger.new('/dev/null')
        ActiveRecord::Base.establish_connection(@config)
	# has_and_belongs_to_many requires a connection so configure the
        # associations here rather than in the class definitions above.
       end

      def user_by_jid(jid)
        jid = JID.new(jid).bare.to_s
        Sql::User.where(email: jid).first
      end

      def fragment_by_jid(jid, node)
        jid = JID.new(jid).bare.to_s
        clause = 'user_id=(select id from users where jid=?) and root=? and namespace=?'
        Sql::Fragment.where(clause, jid, node.name, node.namespace.href).first
      end

      def groups(contact)
        contact.groups.map {|name| Sql::Group.find_or_create_by_name(name.strip) }
      end
    end
  end
end
