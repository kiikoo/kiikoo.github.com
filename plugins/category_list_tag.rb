module Jekyll
  class CategoryListTag < Liquid::Tag
   # def render(context)
   #   html = ""
   #   categories = context.registers[:site].categories.keys
   #   categories.sort.each do |category|
   #     posts_in_category = context.registers[:site].categories[category].size
   #     category_dir = context.registers[:site].config['category_dir']
   #     category_url = File.join(category_dir, category.gsub(/_|\P{Word}/, '-').gsub(/-{2,}/, '-').downcase)
   #     html << "<li class='category'><a href='/#{category_url}/'>#{category} (#{posts_in_category})</a></li>\n"
   #   end
   #   html
   # end
    def initialize(tag_name, markup, tokens)
      @opts = {}
      if markup.strip =~ /\s*counter:(\w+)/iu
        @opts['counter'] = $1
        markup = markup.strip.sub(/counter:\w+/iu,'')
      end
      super
    end

    def render(context)
      html = ""
      config = context.registers[:site].config
      category_dir = config['root'] + config['category_dir'] + '/'
      categories = context.registers[:site].categories
      categories.keys.sort_by{ |str| str.downcase }.each do |category|
        url = category_dir + category.gsub(/_|\P{Word}/u, '-').gsub(/-{2,}/u, '-').downcase
        html << "<li><a href='#{url}'>#{category.capitalize}"
        #if @opts['counter']
          html << " (#{categories[category].count})"
        #end
        html << "</a></li>"
      end
      html
    end
  end
end

Liquid::Template.register_tag('category_list', Jekyll::CategoryListTag)
