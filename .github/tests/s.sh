#!/bin/bash

json='{"tracks":[{"properties":{"language":"eng"}},{"properties":{"language":"eng"}},{"properties":{"language":"fre"}}]}'

echo "$json" | jq -c --argjson rules_raw '{"languages":{"eng":1,"fre":-1,"mis":-1,"zxx":-1}}' '
def parse_rules(rules):
  {
    languages: (rules.languages // {}),
    forced_languages: (rules.forced_languages // {}),
    default_languages: (rules.default_languages // {})
  };

def apply_rules(tracks; $rules):
  [tracks[] | .properties.language as $lang | . as $track |
    if $rules.languages[$lang] == -1 then
      .
    elif $rules.languages[$lang] == 0 then
      .striptracks_keep = false | debug
    else
      $rules | debug | .languages[$lang] -= 1 | $track
    end
  ];

# Parse input JSON and rules, then apply logic
if (.tracks | map(.properties.language as $lang | select($rules_raw.languages | has($lang)))) then
  .
else empty end

'