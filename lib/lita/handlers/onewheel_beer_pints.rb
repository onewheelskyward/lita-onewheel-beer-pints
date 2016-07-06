require 'rest-client'
require 'nokogiri'
require 'lita-onewheel-beer-base'

module Lita
  module Handlers
    class OnewheelBeerPints < OnewheelBeerBase
      route /^pints$/i,
            :taps_list,
            command: true,
            help: {'pints' => 'Display the current taps.'}

      route /^pints ([\w ]+)$/i,
            :taps_deets,
            command: true,
            help: {'pints 4' => 'Display the tap 4 deets, including prices.'}

      route /^pints ([<>=\w.\s]+)%$/i,
            :taps_by_abv,
            command: true,
            help: {'pints >4%' => 'Display beers over 4% ABV.'}

      route /^pints ([<>=\$\w.\s]+)$/i,
            :taps_by_price,
            command: true,
            help: {'pints <$5' => 'Display beers under $5.'}

      route /^pints (roulette|random)$/i,
            :taps_by_random,
            command: true,
            help: {'pints roulette' => 'Can\'t decide?  Let me do it for you!'}

      route /^pintsabvlow$/i,
            :taps_low_abv,
            command: true,
            help: {'pintsabvlow' => 'Show me the lowest abv keg.'}

      route /^pintsabvhigh$/i,
            :taps_high_abv,
            command: true,
            help: {'pintsabvhigh' => 'Show me the highest abv keg.'}

      def taps_list(response)
        beers = self.get_source
        reply = 'Pints taps: '
        beers.each do |tap, datum|
          reply += "#{tap}) "
          reply += datum[:name] + ' '
          # reply += datum[:abv].to_s + '% ABV '
          # reply += datum[:ibu].to_s + ' IBU '
        end
        reply = reply.strip.sub /,\s*$/, ''

        Lita.logger.info "Replying with #{reply}"
        response.reply reply
      end

      def send_response(tap, datum, response)
        reply = "Pints's tap #{tap}) "
        reply += "#{datum[:name]} "
        reply += datum[:abv].to_s + '% ABV '
        reply += datum[:ibu].to_s + ' IBU '
        reply += "- #{datum[:desc]}, "

        Lita.logger.info "send_response: Replying with #{reply}"

        response.reply reply
      end

      def get_source
        Lita.logger.debug 'get_source started'
        unless (response = redis.get('page_response'))
          Lita.logger.info 'No cached result found, fetching.'
          response = RestClient.get('http://www.pintsbrewing.com/brew-menu/')
          redis.setex('page_response', 1800, response)
        end
        parse_response response
      end

      # This is the worker bee- decoding the html into our "standard" document.
      # Future implementations could simply override this implementation-specific
      # code to help this grow more widely.
      def parse_response(response)
        Lita.logger.debug 'parse_response started.'
        gimme_what_you_got = {}
        got_beer = false
        tap = 1
        beer_name = nil
        beer_abv = nil
        beer_ibu = nil
        beer_desc = nil

        noko = Nokogiri.HTML response
        noko.css('.entry-content p').each do |beer_node|
          # gimme_what_you_got
          if got_beer
            beer_desc = beer_node.children.to_s
            got_beer = false
            full_text_search = "#{beer_name} #{beer_desc.to_s.gsub /\d+\.*\d*%*/, ''}"

            gimme_what_you_got[tap] = {
                # type: tap_type,
                # brewery: brewery.to_s,
                name: beer_name.to_s,
                desc: beer_desc.to_s,
                abv: beer_abv.to_f,
                ibu: beer_ibu.to_i,
                # prices: prices,
                # price: prices[1][:cost],
                search: full_text_search
            }
            tap += 1
          end

          if !got_beer and beer_node.to_s.match(/\d+ IBU/)
            got_beer = true
            # beer_name = nil
            # beer_abv = nil
            # beer_ibu = nil

            data = beer_node.css('strong')
            beer_name = data.children.first.to_s
            beer_name.strip!
            beer_name.sub! /\s+…+.* ABV.*IBU/, ''
            beer_abv = data.children.last.to_s[/\d+\.\d+% ABV/]
            beer_abv.sub! /% ABV/, ''
            beer_ibu = data.children.last.to_s[/\d+ IBU/]
            beer_ibu.sub! /\sIBU/, ''
          end

        end
        gimme_what_you_got
      end

      Lita.register_handler(self)
    end
  end
end
