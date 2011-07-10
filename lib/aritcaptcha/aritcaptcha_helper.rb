require 'RMagick'
include Magick
require "aritcaptcha/calculation"

module Aritcaptcha

  module AritcaptchaHelper
    ADD = '+'
    SUB = '-'
    DIV = '/'
    MUL = '*'

    OPERATIONS = [ADD, SUB, DIV, MUL]

   def aritcaptcha_tag(options={})
      equation_key = gen_rand_name

      default_operations = {:add => "+", :sub => "-", :mul => "*", :div => "/"}

      operator = nil
      if options[:operations] == nil
         operator = default_operations.to_a[rand(default_operations.size)][1]
      else
         non_default_operations = {}
         options[:operations].each do |op|
            non_default_operations[op] = default_operations[op]
         end
         operator = non_default_operations.to_a[rand(non_default_operations.size)][1]
      end
      equation, result = Aritcaptcha::Calculation.generate_calculation 50, 50, operator

      session[:equation] = [equation_key, eval(equation)]

      if options[:html]
        options_html = options[:html].inject([]) { |dump, pair| dump << "#{pair[0]}=\"#{pair[1]}\"" }
        options_html = options_html.join(" ")
      end
      html = ""
      if options[:format] == "image"
         session[:image] = equation_key
         img = generate_image equation_key, equation

         config = Rails.application.config
         html << "<img src=\"#{config.s3_base_path}/#{config.aritcaptcha_s3_bucket}/aritcaptcha/#{img}\" style='vertical-align:top;' /> <input type=\"text\" name=\"equation\" size=\"3\" style='vertical-align:top;' #{options_html unless options_html.nil?} />"
      else
        html << "#{equation} = <input type=\"text\" name=\"equation\" style='vertical-align:top;' size=\"3\" #{options_html unless options_html.nil?} /></div>"
      end
      html << "<input type=\"hidden\" name=\"equation_key\" value=\"#{equation_key}\" /> \n"
    end

    def generate_image(equation_key, equation)
      relative_name = "aritcaptcha-#{equation_key}.png"
      full_path     = "#{Rails.root}/tmp/#{relative_name}"
      unless File.file?(full_path)
         image = Magick::Image.new(85, 32)
         image.format = "PNG"
         title = Magick::Draw.new
         title.annotate(image, 5, 5, 12, 7, equation + " =") do
           self.fill        = "#333"
           self.font        = Rails.root.to_s + "/fonts/Clarenton LT Bold.ttf"
           self.font_family = "Clarenton LT Bold"
           self.font_weight = Magick::BoldWeight
           self.gravity     = Magick::NorthWestGravity
           self.pointsize   = 15
         end
         image.write(full_path)

         s3_bucket = Rails.application.config.aritcaptcha_s3_bucket
         if connect_to_amazon_s3 s3_bucket
           AWS::S3::S3Object.store('aritcaptcha/'+relative_name, open(full_path),
                                    s3_bucket, :access => :public_read)
         end
      end      
       relative_name
    end

    def connect_to_amazon_s3(bucket_name)
      AWS::S3::Base.establish_connection! \
        :access_key_id => ENV['S3_KEY'],
        :secret_access_key => ENV['S3_SECRET']
      
      buckets = AWS::S3::Service.buckets
      unless buckets.map {|b| b.name}.include? bucket_name
        puts " >> WARNING: The bucket '#{bucket_name}' does not exist!"
        return false
      end
      return true
    end

    def gen_rand_name
      # 7 character name with random uppercase & lowercase letters
      Time.now.to_i.to_s + (1..7).map { (65 + rand(2) * 32 + rand(25)).chr }.join
    end

  end

end