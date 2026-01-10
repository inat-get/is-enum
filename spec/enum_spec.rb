
require_relative 'spec_helper'

RSpec.describe IS::Enum do

  it "values" do
    expect(Alpha.values.size).to eq(4)
    expect(Alpha.aliases.size).to eq(1)
    expect(Alpha.beta == Alpha.bi).to eq(true)
    expect(Alpha.beta.eql? Alpha.bi).to eq(false)
    expect(Alpha.Gamma.eql? Alpha.g_letter).to eq(true)
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
  end

end
