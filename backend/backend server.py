from flask import Flask
from flask_socketio import SocketIO, emit

app = Flask(__name__)
app.config['SECRET_KEY'] = 'secret!'
socketio = SocketIO(app, cors_allowed_origins="*")

@socketio.on('connect')
def handle_connect():
    print('Client connected')

@socketio.on('toggle')
def handle_toggle(data):
    print('Toggle state received:', data)
    emit('response', {'status': 'Received'}, broadcast=True)

@socketio.on('handle')
def handle_user_handle(data):
    print('Handle received:', data)
    emit('response', {'status': 'Handle Received'}, broadcast=True)

@socketio.on('disconnect')
def handle_disconnect():
    print('Client disconnected')

if __name__ == '__main__':
    socketio.run(app, host='127.0.0.1', port=6969)
