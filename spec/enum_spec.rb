
require_relative 'spec_helper'

RSpec.describe IS::Enum do

  it "values" do
    expect(Alpha.values.size).to eq(4)
    expect(Alpha.aliases.size).to eq(1)
    expect(Alpha.beta == Alpha.bi).to eq(true)
    expect(Alpha.beta.eql? Alpha.bi).to eq(false)
    expect(Alpha.Gamma.eql? Alpha.g_letter).to eq(true)
    expect(Alpha[10]).to eq(Alpha.alpha)
  end

  it "order" do
    expect(Alpha.alpha.succ).to eq(Alpha.beta)
  end

  it "enumerable" do
    expect(Alpha.first).to eq(Alpha.alpha)
    expect(Alpha.last).to eq(Alpha.Gamma)
  end

  it "comparable" do
    expect(Alpha.alpha < 20).to eq(true)
    expect(Alpha.alpha < 10).to eq(false)
    expect(Alpha.alpha == :alpha).to eq(true)
    expect(Alpha.alpha <=> []).to eq(nil)
  end

  it "parse" do
    expect(IS::Enum.parse 'Alpha.alpha').to eq(Alpha.alpha)
    expect(Alpha.parse 'beta').to eq(Alpha.beta)
  end

  it "of" do
    expect(Alpha.of :alpha).to eq(Alpha.alpha)
  end

  it "from" do
    expect(Alpha.from nil).to eq(nil)
    expect(Alpha.from Alpha.alpha).to eq(Alpha.alpha)
    expect(Alpha.from(:alpha..:Gamma)).to eq((Alpha.alpha..Alpha.Gamma))
    a = [ 'alpha', :beta ]
    expect(Alpha.from a).to eq([Alpha.alpha, Alpha.beta])
    expect(Alpha.from Set[*a]).to eq(Set[Alpha.alpha, Alpha.beta])
  end

  it "conversion" do
    expect(Alpha.alpha.to_sym).to eq(:alpha)
    expect(Alpha.alpha.to_s).to eq('alpha')
    expect(Alpha.alpha.inspect).to eq('[enum Alpha.alpha order_no=10]')
    expect(Alpha.to_range).to eq(Alpha.alpha .. Alpha.Gamma)
  end

  it "each" do
    c = 0
    e = Alpha.each do |v|
      c += v.order_no
    end
    expect(e).to eq(Alpha)
    expect(c).to eq(80)
  end

  it "hash" do
    h = Alpha.to_h
    expect(h[:Gamma]).to eq(h[:g_letter])
  end

end
