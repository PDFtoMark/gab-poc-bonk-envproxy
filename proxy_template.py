import socket, ssl, threading
LOG = open('/tmp/proxy.log', 'a', buffering=1)
ctx = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
ctx.load_cert_chain('/tmp/leaf.pem', '/tmp/leaf.key')

def mode():
    try:
        return open('/tmp/mode').read().strip() or 'admin'
    except Exception:
        return 'admin'

def body_for(path):
    if '/collaborators/' in path and path.endswith('/permission'):
        return '{"permission":"%s"}' % mode()
    if path.endswith('/api/github/setup'):
        return '{"exists":true}'
    if '/exchange_github_app_token' in path:
        return '{"token":"poc-fake-installation-token"}'
    if '/api/github/track' in path:
        return '{"ok":true}'
    return '{"exists":true}'

def handle(c):
    try:
        c.settimeout(20)
        data = b''
        while b'\r\n\r\n' not in data:
            chunk = c.recv(4096)
            if not chunk:
                return
            data += chunk
        LOG.write('REQ: %s\n' % data.split(b'\r\n')[0].decode(errors='replace'))
        if data.startswith(b'CONNECT'):
            c.sendall(b'HTTP/1.1 200 Connection established\r\n\r\n')
            s = ctx.wrap_socket(c, server_side=True)
            inner = b''
            while b'\r\n\r\n' not in inner:
                chunk = s.recv(4096)
                if not chunk:
                    break
                inner += chunk
            head = inner.decode(errors='replace')
            parts = head.split(' ')
            path = parts[1] if len(parts) > 1 else '/'
            LOG.write('INTERCEPTED %s\n' % head.split('\r\n')[0])
            for line in head.split('\r\n'):
                if line.lower().startswith('authorization:'):
                    LOG.write('  auth_header_seen len=%d\n' % len(line))
            body = body_for(path).encode()
            s.sendall(b'HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nContent-Length: '
                      + str(len(body)).encode() + b'\r\nConnection: close\r\n\r\n' + body)
            try:
                s.close()
            except Exception:
                pass
    except Exception as e:
        LOG.write('ERR %r\n' % (e,))
    finally:
        try:
            c.close()
        except Exception:
            pass

srv = socket.socket()
srv.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
srv.bind(('127.0.0.1', 8899))
srv.listen(20)
LOG.write('LISTENING 8899 mode=%s\n' % mode())
while True:
    conn, _ = srv.accept()
    threading.Thread(target=handle, args=(conn,), daemon=True).start()
