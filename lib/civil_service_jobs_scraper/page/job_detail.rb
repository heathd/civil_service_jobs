# typed: true
class CivilServiceJobsScraper::Page::JobDetail
  sig {returns(Mechanize::Page)}
  attr_reader :page

  sig {params(page: Mechanize::Page).void}
  def initialize(page)
    @page = page
  end

  sig {returns(T::Hash[Symbol, String])}
  def side_panel_fields
    db_friendly_names(side_panel_fields_kv)
  end

  sig {returns(String)}
  def body
    page.css('.vac_display_panel_main').inner_html
  end

private
  sig {params(kv: T::Array[T::Array[String]]).returns(T::Hash[Symbol, String])}
  def db_friendly_names(kv)
    Hash[kv.map {|n,v| [db_friendly_name(n), v.to_s]}]
  end

  sig {params(name: T.nilable(String)).returns(Symbol)}
  def db_friendly_name(name)
    name.to_s.downcase.gsub(" ", "_").to_sym
  end

  sig {returns(T::Array[T::Array[String]])}
  def side_panel_fields_kv
    page.css('.vac_display_panel_side .vac_display_field').inject([]) do |memo, div|
      values = div.css('.vac_display_field_value').map {|v| v.text.strip}
      name = div.css('h3').text.strip

      if name.empty?
        n, v = memo.last
        vv = ([v] + values).join("\n")
        memo[0...-1] + [[n, vv]]
      elsif values.size == 1
        memo + [[name, values.first]]
      else
        distinct_names = values.size.times.map {|n| "#{name}_#{n}"}
        memo + distinct_names.zip(values)
      end
    end
  end
end
