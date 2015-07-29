class Hash
	#struct of xml
	MAPPING={
		FN: ["NAME", "SURNAME"],
		N:{ 
			FAMILY: "SURNAME",
			GIVEN: "NAME"
		},
		NICKNAME: "NICK",
		URL: "URL",
		ADR:{
			LOCALITY: "CITY",
			CTRY: "CONTRY"
		},
		TEL: {
			NUMBER: "PHONE"
		},
		EMAIL:{
			USERID: "EMAIL"
		},
		BDAY: "BDAY",
		DESC: "OTHER"
	}
	
	def deep_copy
		Marshal::load(Marshal.dump(self))
	end
	
	def build_vcard(o=nil)
		return !(o) ? MAPPING.deep_copy.build_vcard(self).to_vcard : self.each{|k,v| self[k]=v.build_vcard(o)}
	end
	
	def build_hash(o=nil)
		if !(o) then 
			self[:vCard] ? (o=MAPPING.build_hash(self[:vCard])).each{|k,v| o.delete(k) if v.nil?} : {} 
		else 
			self.inject({}){|c,(k,v)| c.merge(v.build_hash(o[k]))}
		end
	end
	
	def to_vcard
		self.to_xml.gsub("hash","vCard")
	end
end

class Array
	def build_vcard(o=nil)
		return self.map{|e| o[e]}.join(" ")
	end

	def build_hash(o=nil)
		return {}
	end
end

class Object
	def build_vcard(o=nil)
		return o[self]
	end
	
	def build_hash(o=nil)
		return {self => o}
	end	
end

=begin
{:vCard=>{:prodid=>"-//HandGen//NONSGML vGen v1.0//EN", :version=>"2.0", :FN=>" ", :N=>{:FAMILY=>"zxcz", :GIVEN=>"zxczc"}, :NICKNAME=>"ee"}}
{:vCard=>{:prodid=>"-//HandGen//NONSGML vGen v1.0//EN", :version=>"2.0", :FN=>"1", :N=>{:FAMILY=>"2", :GIVEN=>"3"}, :NICKNAME=>"4", :URL=>"5", :ADR=>{:STREET=>"6", :EXTADD=>"7", :LOCALITY=>"8", :REGION=>"9", :PCODE=>"10", :CTRY=>"11"}, :TEL=>{:NUMBER=>"12"}, :EMAIL=>{:USERID=>"13"}, :ORG=>{:ORGNAME=>"14", :ORGUNIT=>"15"}, :TITLE=>"16", :ROLE=>"17", :BDAY=>"18", :DESC=>"123131231313"}}
=end