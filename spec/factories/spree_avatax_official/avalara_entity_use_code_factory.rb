FACTORY_BOT_CLASS.define do
  sequence(:avalara_entity_use_code_code) { |n| "TEST#{n}" }

  factory :avalara_entity_use_code, class: SpreeAvataxOfficial::EntityUseCode do
    code { generate(:avalara_entity_use_code_code) }
    name { 'Federal government' }
    description { 'Federal government' }
  end
end
