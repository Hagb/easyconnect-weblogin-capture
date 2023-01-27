import logging
from urllib.parse import urlparse
from mitmproxy.certs import Cert
from mitmproxy.http import HTTPFlow
from mitmproxy.tls import TlsData


def request(flow: HTTPFlow) -> None:
    if urlparse(flow.request.url).path in ('/por/conf.csp', '/por/rclist.csp'):
        print(f"TWFID has been captured: {flow.request.cookies.get('TWFID')}")
        print("Interrupt the connection!")
        flow.kill()


def response(flow: HTTPFlow) -> None:
    if urlparse(flow.request.url).path == '/com/server.crt':
        if not flow.client_conn.certificate_list:
            logging.error("No certificate on client_conn?!")
            return
        flow.response.content = flow.client_conn.certificate_list[0].to_pem()
    elif flow.response.status_code == 301:
        flow.response.headers['Location'] = flow.response.headers['Location'].replace(
            f"https://{flow.request.host}/", "/")


def tls_established_client(data: TlsData) -> None:
    if data.ssl_conn is None:
        return
    cert = data.ssl_conn.get_certificate()
    if cert is None:
        return
    data.conn.certificate_list = [Cert(cert.to_cryptography())]
