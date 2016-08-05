module ApplicationHelper

  # sometimes discount is decimal, or percentage
  # so evaluate discount price
  # add $100 in discount

  def flash_class(level)
    case level
    when :notice then "alert alert-info"
    when :success then "alert alert-success"
    when :error then "alert alert-error"
    when :alert then "alert alert-error"
    when :info then "alert alert-info"
    when :warning then "alert alert-error"
    end
  end

  def js_date_pick_convert js_picked_date
=begin
    month_match ={"JAN" => "01","FEB" => "02","MAR" =>"03" ,"APR" =>"04","MAY" =>"05" ,"JUN" =>"06" ,"JUL" =>"07" ,"AUG" =>"08","SEP" =>"09" ,"OCT" => "10","NOV"=>"11","DEC"=>"12"}

    ymd_match = js_picked_date.match(/(\d+)-(\w)-(\d+)/)
    convert_date 
=end
  end

  def format_human_name(name)
    name.split(' ').collect{|sub_name| sub_name.capitalize}.join(' ') rescue name
  end
  
  def clean_phone_number(did)
    formatted_did = ""
    begin
      formatted_did = did.gsub('(', '').gsub(')', '').gsub(' ', '').gsub('-', '')
      formatted_did = (formatted_did.length != 10) ? formatted_did[0 .. 9].to_s : formatted_did
      formatted_did.insert(6,"-")
      formatted_did.insert(3,"-")
      formatted_did
    rescue
      formatted_did = did
    end
    
    formatted_did
  end
  
  def get_agent_dashboard_link(current_account)
    unless current_account.nil?
      if current_account.parent_type == "Agent"
        parent_id = current_account.parent.id
        return "/admin/agents/edit/#{parent_id}"
      else
        return "#"
      end
    else
      return "#"
    end
  end
  
  def get_discount_amount total_price,discount_val
    if discount_val>1 then # decimal value
       return discount_val+100
    end
    (total_price * discount_val)+100 # if percentage
  end

  def tabs_for(main_symbol, subtabs=[])
    selected = ' selected' if @selected_tab.to_s == main_symbol.to_s
    html = "<div class=\"layout_tab_container#{' hasNoSubtabs' if subtabs.length == 0}#{' logout' if main_symbol == :logout}#{' selectedContainer' if selected}\">\n"
    html << "<div class=\"layout_tab#{selected}\"><a href=\"/admin/#{main_symbol.to_s}\">"
    if main_symbol == :index
      html << '<img src="/assets/admin/home.png" alt="Home" title="Home"/>'
    else
      html << "#{main_symbol.to_s.capitalize}"
    end
    html << "</a></div>"
    subtabs.each do |subtab|
      # Each subtab is a array like: ['Label', 'path/to/page']
      # or just: 'label' which will be changed to: ['Label', 'label']
      subtab = subtab.to_a
      subtab = [subtab[0].capitalize, subtab[0].downcase] if subtab.length == 1
      html << "<div class=\"layout_tab\"><a href=\"/admin/#{subtab[1]}\">#{subtab[0]}</a></div>"
    end
    html << "</div>"
    html.html_safe
  end
  
  def search_hud_rows(row_params)
    html = ""; index = 0
    row_params.each do |param|
      prefix = "query[#{index}]"
      param_name = (param.class == Array ? param[1] : param).to_s
      
      html << "<tr class=\"#{cycle('', 'CIOddSkin')}\"><td>#{param_name.humanize}</td><td>"
      
      html << "<input type=\"hidden\" name=\"#{prefix}[param]\" value=\"#{param_name}\"/>"
      html << "<select name=\"#{prefix}[op]\">"
      html << '<option value="with">is</option><option value="without">is not</option></select>'
      html << '</td><td>'
      
      if param.class == Array
        html << "<select name=\"#{prefix}[value]\">"
        i = 0
        param[2].each do |label,value|
          selected = ' selected="selected"' if i == 0
          html << "<option value=\"#{value}\"#{selected}>#{label}</option>"
          i += 1
        end
        html << "</select>"
      else
        html << "<input name=\"#{prefix}[value]\" type=\"text\" size=\"15\"/></td></tr>"
      end
      
      index += 1
    end
    return html.html_safe
  end
  
  def selected?(symbol)
    
  end
  
  def strftime_date_time
    "%m/%d/%y %I:%M %p"
  end
  
  def strftime_time
    "%I:%M %p"
  end
  
  def strftime_date
    "%m/%d/%y"
  end
  
  def strftime_mysql_date
    "%Y-%m-%d"
  end
  
  def current_account
    session[:account_id].nil? ? Account.empty_account : Account.find(session[:account_id])
  end
  
  def with_timezone(time)
  	time + current_account.timezone.hours + (time.isdst ? 1.hours : 0.hour)
  end

  def state_select_options
    [
      ["Alabama", "AL"],
      ["Alaska", "AK"],
      ["Arizona", "AZ"],
      ["Arkansas", "AR"],
      ["California", "CA"],
      ["Colorado", "CO"],
      ["Connecticut", "CT"],
      ["Delaware", "DE"],
      ["District of Columbia", "DC"],
      ["Florida", "FL"],
      ["Georgia", "GA"],
      ["Hawaii", "HI"],
      ["Idaho", "ID"],
      ["Illinois", "IL"],
      ["Indiana", "IN"],
      ["Iowa", "IA"],
      ["Kansas", "KS"],
      ["Kentucky", "KY"],
      ["Louisiana", "LA"],
      ["Maine", "ME"],
      ["Maryland", "MD"],
      ["Massachusetts", "MA"],
      ["Michigan", "MI"],
      ["Minnesota", "MN"],
      ["Mississippi", "MS"],
      ["Missouri", "MO"],
      ["Montana", "MT"],
      ["Nebraska", "NE"],
      ["Nevada", "NV"],
      ["New Hampshire", "NH"],
      ["New Jersey", "NJ"],
      ["New Mexico", "NM"],
      ["New York", "NY"],
      ["North Carolina", "NC"],
      ["North Dakota", "ND"],
      ["Ohio", "OH"],
      ["Oklahoma", "OK"],
      ["Oregon", "OR"],
      ["Pennsylvania", "PA"],
      ["Rhode Island", "RI"],
      ["South Carolina", "SC"],
      ["South Dakota", "SD"],
      ["Tennessee", "TN"],
      ["Texas", "TX"],
      ["Utah", "UT"],
      ["Vermont", "VT"],
      ["Virginia", "VA"],
      ["Washington", "WA"],
      ["West Virginia", "WV"],
      ["Wisconsin", "WI"],
      ["Wyoming", "WY"]
    ]
  end
  
  def plans_data
    packages = Package.all
    coverages = Coverage.where(:optional => false).includes(:packages)
    coverages.collect do |c|
      [c.coverage_name] + packages.collect {|p| c.packages.include?(p)}
    end
  end

  def plans_table_html(purchase=nil)
    html = "<div class=\"plansTable #{purchase.to_s}\">"
  	headers = ['Covered Items', 'Platinum Care', 'Gold Care', 'Bronze Care']
  	plans = plans_data
  	if purchase
  	  a = ['']
  		Package.find(:all).each do |package|
  		  checked = 'checked="checked"' if package == Package.first
  			s = "<input type=\"radio\" class=\"packageRadioButton\" id=\"customer_coverage_type_#{package.id}\" name=\"customer[coverage_type]\" value=\"#{package.id}\" onclick=\"updatePlanTotal()\" #{checked}/>"
  			s << '<br/>'
  			s << "<label for=\"customer_coverage_type_#{package.id}\" id=\"customer_coverage_type_#{package.id}_label\"></label>"
  		  a << s
  		end
  		plans << a
  	end
  	headers.length.times do |column|
      html << "<div class=\"plansTable#{'Header' if column == 0}Column\">"
      html << "<p class=\"plansTableHeader\">#{headers[column]}</p>"
  		plans.each do |plan|
  		  if column == 0
  				html << "<p>#{plan[column]}</p>"
  			else
  				html << "<p>"
  				if purchase && (plan == plans.last)
  				  html << plan[column]
				  else
  				  html << "<img src=\"/assets/site/plans/offered.png\" alt=\"offered\" />" if plan[column]
  				end
  				html << "</p>"
  			end # if column == 0
  		end # plans.each
  	  html << "</div>"
	  end # headers.length.times do
    html << "</div>" # div.plansTable
    html.html_safe
  end #plans_table_html
  
  def google_analytics_js
    return '' unless Rails.env.production?
    script = <<-HTML
    <script type="text/javascript">
      var _gaq = _gaq || [];
      _gaq.push(['_setAccount', '#{$installation.ga_tracking_id}']);
      _gaq.push(['_setDomainName', 'selecthomewarranty.com']);
      _gaq.push(['_trackPageview']);

      (function() {
        var ga = document.createElement('script'); ga.type = 'text/javascript'; ga.async = true;
        ga.src = ('https:' == document.location.protocol ? 'https://ssl' : 'http://www') + '.google-analytics.com/ga.js';
        var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(ga, s);
      })();
    </script>
    HTML
    script.html_safe
  end

  def est_time_zone
    Time.now.in_time_zone('Eastern Time (US & Canada)').strftime("%I:%M %p")
  end

  def cst_time_zone
    Time.now.in_time_zone('Central Time (US & Canada)').strftime("%I:%M %p")
  end

  def pst_time_zone
     Time.now.in_time_zone('Pacific Time (US & Canada)').strftime("%I:%M %p")
  end

  def display_rating_for_contractor(star)
    if star == 5
      return "A"
    elsif star == 4
      return "B"
    elsif star == 3
      return "C"
    elsif star == 2
      return "D"
    elsif star == 1
      return "E"
    else
      return ""
    end
  end
end
