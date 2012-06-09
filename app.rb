# Use the app.rb file to load Ruby code, modify or extend the models, or
# do whatever else you fancy when the theme is loaded.

require 'pony'              # mail handler
require 'rack/recaptcha'

module Nesta
  module View
    module Helpers

      def article_summaries(articles, liclasses = "")
        haml(:summaries, :layout => false, :locals => { :pages => articles, :liclasses => liclasses })
      end

      def filter_for_categories(pages,cats)
        pages.select do |page|
          tp = Page.find_by_path(cats)
          val = page.categories.include?(tp)
          val
        end
      end

      def filter_out_categories(pages,cats)
        pages.select do |page|
          tp = Page.find_by_path(cats)
          val = !page.categories.include?(Page.find_by_path(cats))
          val
        end
      end
    end
  end
  module Navigation
    module Renderers
      # override to pass "active" to bootstrap instead of "current"
      def display_menu_item(item, options = {})
        if item.respond_to?(:each)
          if (options[:levels] - 1) > 0
            haml_tag :li do
              display_menu(item, :levels => (options[:levels] - 1))
            end
          end
        else
          html_class = current_item?(item) ? "active" : nil
          haml_tag :li, :class => html_class do
            haml_tag :a, :<, :href => url(item.abspath) do
              haml_concat link_text(item)
            end
          end
        end
      end
    end
  end
  class App
    # Uncomment the Rack::Static line below if your theme has assets
    # (i.e images or JavaScript).
    #
    # Put your assets in themes/bootstrap/public/bootstrap.
    #
    use Rack::Static, :urls => ["/bootstrap"], :root => "themes/bootstrap/public"

    use Rack::Recaptcha, :public_key => ENV['RECAPTCHA_PUBLIC_KEY'], :private_key => ENV['RECAPTCHA_PRIVATE_KEY']

    helpers Rack::Recaptcha::Helpers



    not_found do
      haml :error
    end

    helpers do
      def container
        if @page && @page.flagged_as?('fluid')
          'container-fluid'
        else
          'container'
        end
      end

      def page_list_by_date( pages )
        haml_tag :ul do
          pages.each do |pg|
            haml_tag :li do
              haml_tag :a, :href => "##{pg.path.gsub(/\//,"_")}" do
                haml_concat "#{format_date(pg.date)}"
              end
            end
          end
        end
      end

      def page_list_by_title( page )
        haml_tag :ul do
          page.each do |pg|
            haml_tag :li do
              haml_tag :a, :href => "##{pg.path.gsub(/\//,"_")}" do
                haml_concat "#{pg.title}"
              end
            end
          end
        end
      end
    end

    # Add new routes here.

    get '/css/:sheet.css' do
      content_type 'text/css', :charset => 'utf-8'
      cache stylesheet(params[:sheet].to_sym)
    end

    post '/contact' do
      redirect to('/contact') unless recaptcha_valid?

      # $stderr.puts "SENDING #{params}"
      # $stderr.puts "SENDING #{params[:name]} <#{params[:email]}>"
      # $stderr.puts "ENV #{ENV['SMTP_HOST']} #{ENV['SENDGRID_USERNAME']} #{ENV['SENDGRID_PASSWORD']} #{ENV['SENDGRID_DOMAIN']}"
      Pony.mail(
                :from => "#{params[:name]} <#{params[:email]}>",
                :to => ENV['CONTACT_ADDRESS'] || 'crindt@gmail.com <crindt@gmail.com>',
                :subject => "#{params[:name]} has contacted you regarding: #{params[:subject]}",
                :body => params[:message],
                :port => '587',
                :via => :smtp,
                :via_options => {
                  :address              => ENV['SMTP_HOST'] || 'smtp.sendgrid.net',
                  :port                 => '587',
                  :enable_starttls_auto => true,
                  :user_name            => ENV['SENDGRID_USERNAME'],
                  :password             => ENV['SENDGRID_PASSWORD'],
                  :authentication       => :plain, 
                  :domain               => ENV['SENDGRID_DOMAIN']
                }
                )
      redirect '/success' 
    end
  end
end
