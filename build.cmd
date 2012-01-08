ruby railgen.rb pve-6-rails.yaml
ruby railgen.rb -t templates/subwaymap.haml pve-6-rails.yaml
python generate-nodes.py pve-6-rails.yaml pve-6-rails-connection.js  --javascript --quiet
