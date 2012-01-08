ruby railgen.rb reddit-pve-6-rails.yaml
ruby railgen.rb -t templates/subwaymap.haml reddit-pve-6-rails.yaml
python generate-nodes.py reddit-pve-6-rails.yaml pve-6-rails-connection.js  --javascript --quiet
