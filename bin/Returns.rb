require 'thread'
require 'watir-webdriver'

module Returns
	extend self
	
	config = ARGV.shift || File.join(File.dirname($0), "..", "etc", "config")
	unless File.exists? config
		puts "Can't find config file #{config}"
		puts "Either create it or specify another config file with: #{File.basename $0} [filename]"
		exit
	end
	load config

	class Returner
		def initialize
			@ignorePenalties = ReturnsConfig::IGNOREPENALTIES
			@browserType = ReturnsConfig::BROWSERTYPE

			@user = ReturnsConfig::Conn::USER
			@password = ReturnsConfig::Conn::PASSWORD
			@loginPage = ReturnsConfig::Conn::LOGINPAGE
			@createPage = ReturnsConfig::Conn::CREATEPAGE

			@userField = ReturnsConfig::Structure::USERFIELD
			@passField = ReturnsConfig::Structure::PASSFIELD
			@loginButton = ReturnsConfig::Structure::LOGINBUTTON
			@notAuthText = ReturnsConfig::Structure::NOAUTHTEXT
			@editLink = ReturnsConfig::Structure::EDITLINK
			@createLink = ReturnsConfig::Structure::CREATELINK
			@nrText = ReturnsConfig::Structure::NRTEXT
			@penalizedText = ReturnsConfig::Structure::PENALIZEDTEXT
			@itemCountName = ReturnsConfig::Structure::ITEMCOUNTNAME
			@updateName = ReturnsConfig::Structure::UPDATENAME
			@productField = ReturnsConfig::Structure::PRODUCTFIELD
			@addButton = ReturnsConfig::Structure::ADDBUTTON
			@errorClass = ReturnsConfig::Structure::ERRORCLASS

			@stoppable = true
			@b = Watir::Browser.new @browserType
		end

		def login
			@b.goto @loginPage
			@b.text_field(:id => @userField).set @user
			@b.text_field(:id => @passField).set @password
			@b.button(:id => @loginButton).click

			if @b.text.include? @notAuthText
				puts "Couldn't log in with supplied username/password."
				exit
			end
		end

		def open_returns
			@b.goto(@createPage)
			if @b.link(:href => @editLink).exists?
				@b.link(:href => @editLink).click
			elsif @b.link(:href => @createLink).exists?
				@b.link(:href => @createLink).click
			else
				puts "Couldn't find a way to create or edit returns once logged in."
				exit
			end
		end

		def start
			@stoppable = true
			self.login
			self.open_returns
			loop do
				@isbn = inQ.pop
				@stoppable = false
				@b.text_field(:name => @productField).set @isbn
				@b.button(:value => @addButton).click
				if @b.div(:class => @errorClass, :text => @nrText).exists?
					nonReturnableQ << @isbn
				elsif @b.div(:class => @errorClass, :text => @penalizedText).exists?
					penalizedQ << @isbn
					unless @ignorePenalties
						(@b.text_field(:name => @itemCountName).set(b.text_field(:name => @itemCountName).value.to_i - 1))
						@b.button(:name => @updateName).click
					end
				end
				processedQ << @isbn
				@stoppable = true
			end
		end

		def stop
			until @stoppable
			end
			@b.close
		end
	end
end
