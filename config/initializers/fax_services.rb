class EFaxFaxService
  def self.deduce_sender_fax_number_using_envelope(envelope)
    # Check subject
    #   Primary: "19732011333", "915 941 0868", "unknown", "Sender Name"
    #   Seconday: Caller-ID: XXX-XXX-XXXX, Caller-ID: UNAVAILABLE
    #    3rd just RingCentral : New Fax Message from (XXX) XXX-XXXX 

    primary_match = envelope.subject.match(/"(.+?)"/) unless envelope.subject.nil?
    if primary_match
      primary = primary_match[1].gsub(/[\D]/, '')
      match = primary.match(/\d{10}$/)
      return match[0] if match
    end
    
    secondary_match = envelope.subject.match(/ID:\s*(.+?)$/) unless envelope.subject.nil?
    if secondary_match
      secondary = secondary_match[1].gsub(/[\D]/, '')
      match = secondary.match(/\d{10}$/)
      return match[0] if match
    end

    third_match=envelope.subject.match(/(\(\d{3}\)\s\d{3}-\d{4})/) unless envelope.subject.nil?
    if third_match
      third = third_match[1].gsub(/[\D]/, '')
      match = third.match(/\d{10}$/)
      return match[0] if match
    end
  end
end

class OneSuiteFaxService
  def self.deduce_sender_fax_number_using_envelope(envelope)
    return envelope.subject.scan(/\d{10}/)[0] || envelope.body.scan(/OS FAX Number\s*:\s*(\d{10})/).flatten[0]
  end
end
