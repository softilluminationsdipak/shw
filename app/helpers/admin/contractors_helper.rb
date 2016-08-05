module Admin::ContractorsHelper
  def format_did(did)
    "(" + did[0 .. 2].to_s + ") " + did[3 .. 5].to_s + "-" + did[6 .. 9].to_s
  end
  
  def prev_of_character(cur)
    if cur == "A" then
      return "0"
    end
    
    ("A".."Y").each do |character|
      if character.succ == cur then
        return character
      end
    end
    
    "0"
  end
  
end
