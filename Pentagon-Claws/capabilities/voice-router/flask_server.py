from flask import Flask, request, jsonify, send_from_directory
import requests
import os

app = Flask(__name__, static_folder='.')

WHISPER_URL = "http://10.0.0.76:9000"

# Discord webhook - posts to your channel as a voice message
# We'll use the message tool internally instead

@app.route('/')
def index():
    return send_from_directory('.', 'index.html')

@app.route('/<path:path>')
def static_files(path):
    return send_from_directory('.', path)

@app.route('/v1/audio/transcriptions', methods=['POST', 'OPTIONS'])
def proxy_whisper():
    if request.method == 'OPTIONS':
        response = jsonify({})
        response.headers['Access-Control-Allow-Origin'] = '*'
        response.headers['Access-Control-Allow-Methods'] = 'POST, OPTIONS'
        response.headers['Access-Control-Allow-Headers'] = 'Content-Type'
        return response
    
    try:
        files = {}
        for key, file in request.files.items():
            files[key] = (file.filename, file.read(), file.content_type)
        
        resp = requests.post(
            f"{WHISPER_URL}/v1/audio/transcriptions",
            files=files,
            timeout=120
        )
        
        result = jsonify(resp.json())
        result.headers['Access-Control-Allow-Origin'] = '*'
        return result
    except Exception as e:
        result = jsonify({"error": str(e)})
        result.headers['Access-Control-Allow-Origin'] = '*'
        return result, 500

@app.route('/route', methods=['POST', 'OPTIONS'])
def route_to_agent():
    if request.method == 'OPTIONS':
        response = jsonify({})
        response.headers['Access-Control-Allow-Origin'] = '*'
        response.headers['Access-Control-Allow-Methods'] = 'POST, OPTIONS'
        response.headers['Access-Control-Allow-Headers'] = 'Content-Type'
        return response
    
    try:
        data = request.json
        text = data.get('text', '')
        
        if not text:
            return jsonify({"error": "No text provided"}), 400
        
        # Write to a queue file that we can poll
        queue_file = os.path.join(os.path.dirname(__file__), 'voice_queue.txt')
        with open(queue_file, 'a') as f:
            f.write(f"{text}\n---END---\n")
        
        # Set status to show message was received
        status_file = os.path.join(os.path.dirname(__file__), 'agent_status.txt')
        with open(status_file, 'w') as f:
            f.write('received')
        
        return jsonify({"ok": True, "routed": "queued"})
    except Exception as e:
        print(f"Route error: {e}")
        return jsonify({"ok": False, "error": str(e)}), 500

@app.route('/status', methods=['GET', 'POST'])
def agent_status():
    status_file = os.path.join(os.path.dirname(__file__), 'agent_status.txt')
    if request.method == 'POST':
        data = request.json
        with open(status_file, 'w') as f:
            f.write(data.get('status', 'idle'))
        return jsonify({"ok": True})
    else:
        if os.path.exists(status_file):
            with open(status_file, 'r') as f:
                return jsonify({"status": f.read().strip()})
        return jsonify({"status": "idle"})

@app.route('/queue', methods=['GET'])
def get_queue():
    """Poll endpoint for voice messages"""
    queue_file = os.path.join(os.path.dirname(__file__), 'voice_queue.txt')
    if os.path.exists(queue_file):
        with open(queue_file, 'r') as f:
            content = f.read()
        # Clear the queue
        os.remove(queue_file)
        messages = [m.strip() for m in content.split('---END---') if m.strip()]
        return jsonify({"messages": messages})
    return jsonify({"messages": []})

@app.route('/responses', methods=['GET'])
def get_responses():
    """Poll endpoint for agent responses back to the app"""
    resp_file = os.path.join(os.path.dirname(__file__), 'response_queue.txt')
    if os.path.exists(resp_file):
        with open(resp_file, 'r') as f:
            content = f.read()
        os.remove(resp_file)
        messages = [m.strip() for m in content.split('---END---') if m.strip()]
        return jsonify({"messages": messages})
    return jsonify({"messages": []})

@app.route('/respond', methods=['POST'])
def add_response():
    """Endpoint for agent to send response back to app"""
    data = request.json
    text = data.get('text', '')
    if text:
        resp_file = os.path.join(os.path.dirname(__file__), 'response_queue.txt')
        with open(resp_file, 'a') as f:
            f.write(f"{text}\n---END---\n")
        return jsonify({"ok": True})
    return jsonify({"error": "No text"}), 400

@app.route('/health')
def health():
    return jsonify({"status": "ok"})

if __name__ == '__main__':
    os.chdir(os.path.dirname(os.path.abspath(__file__)))
    app.run(
        host='0.0.0.0',
        port=8443,
        ssl_context=('cert.pem', 'key.pem')
    )
