require 'spec_helper'

describe Lita::Handlers::OnewheelBeerPints, lita_handler: true do
  it { is_expected.to route_command('pints') }
  it { is_expected.to route_command('pints 4') }
  it { is_expected.to route_command('pints <$4') }
  it { is_expected.to route_command('pints <=$4') }
  it { is_expected.to route_command('pints >4%') }
  it { is_expected.to route_command('pints >=4%') }
  it { is_expected.to route_command('pintsabvhigh') }
  it { is_expected.to route_command('pintsabvlow') }

  before do
    mock = File.open('spec/fixtures/pints.html').read
    allow(RestClient).to receive(:get) { mock }
  end

  it 'shows the taps' do
    send_command 'pints'
    expect(replies.last).to eq("Pints taps: 1) Brick House Blonde 2) Seismic IPA 3) Rip Saw Red 4) Steel Bridge Stout 5) You’re A Peach, Hon’………5.9% ABV – 18 IBU 6) Belgian Breakfast Beer 7) Chocolate Blood Orange Candi Biere 8) Pints Single Hop Pale Series………5.4% ABV – 45 IBU 9) Konvention Kölsch………")
  end

  it 'displays details for tap 4' do
    send_command 'pints brick'
    expect(replies.last).to eq("Pints's tap 1) Brick House Blonde 5.0% ABV 18 IBU - She’s blonde and refreshing! She’s mighty mighty! Brewed with perfect proportions of Northwest hops and malts for a beer that makes an old man wish for younger days. This session ale lets it all hang out with easy drinkability and a light malt finish. …what a winning hand!, ")
  end

end
