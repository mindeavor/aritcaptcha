module Aritcaptcha

  module AritcaptchaVerify
    SOLV_KEY  = 0
    SOLV      = 1

    def verify_aritcaptcha(params)
      if (equation_key = params[:equation_key]) and (equation = params[:equation])
        if session[:equation] and session[:equation][SOLV_KEY] == equation_key and session[:equation][SOLV] == equation.to_i
          return true
        end
      end          
    end

    def clean image
      unless image == nil
        relative_name = "equacao-#{image}.png"
        full_path     = "#{Rails.root}/public/images/#{relative_name}"
        File.delete(full_path)
       end
    end
  end

end