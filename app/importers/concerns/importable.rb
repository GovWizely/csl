# frozen_string_literal: true

module Importable
  extend ActiveSupport::Concern
  # The module provides functionality useful for importing source data, and
  # can be included into any class that will do so.

  included do
    send(:prepend, Prepend)

    class << self
      attr_accessor :disabled

      def disabled?
        !!disabled
      end
    end
  end

  module Prepend
    def import
      Rails.logger.info "#{self.class.name}: import starting."
      start_time = Time.now.utc.iso8601(8)
      super
      model_class.purge_old(start_time)
      model_class.touch_metadata
      Rails.logger.info "#{self.class.name}: import finished."
    end
  end

  def remap_keys(mapping, article_hash)
    article_hash.slice(*mapping.keys).transform_keys { |k| mapping[k] }
  end

  def lookup_country(country_str)
    normalized_country_str = normalize_country(country_str)
    IsoCountryCodes.search_by_name(normalized_country_str).first.alpha2 if normalized_country_str
  rescue IsoCountryCodes::UnknownCodeError
    Rails.logger.error "Could not find a country code for #{country_str}"
    nil
  end

  def country_name_mappings
    @@country_name_mappings ||= YAML.load_file(File.join(Rails.root, "config", "country_mappings.yaml"))
  end

  def normalize_country(country_str)
    country_str = country_str.strip

    mapping = country_name_mappings.find do |_, regexes|
      regexes.any? { |r| r.match country_str }
    end

    if mapping
      name = mapping.first
      # avoid error logs on names we don't have a country to map it to
      name == "<undetermined>" ? nil : name
    else
      country_str
    end
  end

  def parse_date(date_str)
    Date.parse(date_str).to_s
  rescue
    nil
  end

  def parse_american_date(date_str)
    Date.strptime(date_str, "%m/%d/%Y").iso8601
  rescue
    nil
  end

  def extract_fields(parent_node, path_hash)
    path_hash.transform_values { |path| extract_node(parent_node.xpath(path).first) }
  end

  def extract_node(node)
    node_content = node ? node.inner_text.squish : nil
    node_content.present? ? node_content : nil
  end

  def sanitize_entry(entry)
    entry.each do |k, v|
      next unless v.is_a?(String)
      entry[k] = v.present? ? sanitize_value(v) : nil
    end
    entry
  end

  def sanitize_value(v, flavor = "xhtml1")
    html_entities_coder = HTMLEntities.new(flavor)
    html_entities_coder.decode(Sanitize.clean(v)).squish
  end

  def model_class
    self.class.model_class
  end

  module ClassMethods
    def model_class
      name.sub(/Data$/, "").constantize
    end
  end
end
