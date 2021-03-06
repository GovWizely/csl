# frozen_string_literal: true


describe ScreeningList::UvlData, vcr: { cassette_name: "importers/screening_list/uvl.yml" } do
  before { ScreeningList::Uvl.recreate_index }
  let(:fixtures_file) { "#{Rails.root}/spec/fixtures/screening_lists/uvl/uvl.csv" }
  let(:resource) { fixtures_file }
  let(:importer) { described_class.new(fixtures_file) }
  let(:expected) { YAML.load_file("#{File.dirname(__FILE__)}/uvl/results.yaml") }


  it_behaves_like "an importer which indexes the correct documents"
end
