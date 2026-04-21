import sys, re

conf_path, peer_name = sys.argv[1], sys.argv[2]
with open(conf_path) as f:
    content = f.read()

# remove [peer] block with matching comment
pattern = r'\n\[Peer\]\n# ' + re.escape(peer_name) + r'\n(?:.*\n)*?(?=\n\[|$)'
new_content = re.sub(pattern, '', content)

with open(conf_path, 'w') as f:
    f.write(new_content)
print(f'revoked: {peer_name}')