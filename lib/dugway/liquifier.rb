require 'liquid'
require "#{ File.dirname(__FILE__) }/liquid/drops/base_drop"
Dir.glob("#{ File.dirname(__FILE__) }/liquid/**/*.rb").each { |file| require file }

Liquid::Template.register_filter(Dugway::Filters::UtilFilters)
Liquid::Template.register_filter(Dugway::Filters::CoreFilters)
Liquid::Template.register_filter(Dugway::Filters::DefaultPagination)
Liquid::Template.register_filter(Dugway::Filters::UrlFilters)
Liquid::Template.register_filter(Dugway::Filters::FontFilters)

Liquid::Template.register_tag(:checkoutform, Dugway::Tags::CheckoutForm)
Liquid::Template.register_tag(:get, Dugway::Tags::Get)
Liquid::Template.register_tag(:paginate, Dugway::Tags::Paginate)

module Dugway
  class Liquifier
    STYLE_ESCAPE_CHARS = {
      '{{' => '"<<',
      '}}' => '>>"',
      '{%' => '"<',
      '%}' => '">'
    }
    
    def initialize(request)
      @request = request
    end
    
    def render(content, variables={})
      variables.symbolize_keys!

      assigns = default_assigns
      assigns['page_content'] = variables[:page_content]
      assigns['page'] = Drops::PageDrop.new(variables[:page])
      assigns['product'] = Drops::ProductDrop.new(variables[:product])

      registers = default_registers
      registers[:category] = variables[:category]
      registers[:artist] = variables[:artist]

      context = Liquid::Context.new([ assigns, shared_context ], {}, registers)
      Liquid::Template.parse(content).render!(context)
    end
    
    def self.render_styles(css, theme)
      Liquid::Template.parse(css).render!(
        { 'theme' => Drops::ThemeDrop.new(theme.customization) }, 
        :registers => { :settings => theme.settings }
      )
    end
    
    def self.escape_styles(css)
      STYLE_ESCAPE_CHARS.each_pair { |k,v| css.gsub!(k,v) }
      css
    end
    
    def self.unescape_styles(css)
      STYLE_ESCAPE_CHARS.each_pair { |k,v| css.gsub!(v,k) }
      css
    end
    
    private

    def store
      Dugway.store
    end

    def theme
      Dugway.theme
    end

    def cart
      Dugway.cart
    end

    def shared_context
      @shared_context ||= { 'errors' => [] }
    end
    
    def default_assigns
      {
        'store' => Drops::AccountDrop.new(store.account),
        'cart' => Drops::CartDrop.new(cart),
        'theme' => Drops::ThemeDrop.new(theme.customization),
        'pages' => Drops::PagesDrop.new(store.pages.map { |p| Drops::PageDrop.new(p) }),
        'categories' => Drops::CategoriesDrop.new(store.categories.map { |c| Drops::CategoryDrop.new(c) }),
        'artists' => Drops::ArtistsDrop.new(store.artists.map { |a| Drops::ArtistDrop.new(a) }),
        'products' => Drops::ProductsDrop.new(store.products.map { |p| Drops::ProductDrop.new(p) }),
        'contact' => Drops::ContactDrop.new,
        'head_content' => head_content,
        'bigcartel_credit' => bigcartel_credit
      }
    end
    
    def default_registers
      {
        :request => @request,
        :path => @request.path,
        :params => @request.params.with_indifferent_access,
        :currency => store.currency,
        :settings => theme.settings
      }
    end    
    
    def head_content
      content = %{<meta name="generator" content="Big Cartel">}
      
      if google_font_url = ThemeFont.google_font_url_for_theme
        content << %{\n<link rel="stylesheet" type="text/css" href="#{ google_font_url }">}
      end
      
      content
    end
    
    def bigcartel_credit
      '<a href="http://bigcartel.com/" title="Start your own store at Big Cartel now">Online Store by Big Cartel</a>'
    end
  end
end
