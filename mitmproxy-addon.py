from urllib.parse import urlparse
import logging
from mitmproxy import http, ctx


def request(flow: http.HTTPFlow) -> None:
    if urlparse(flow.request.url).path in ('/por/conf.csp', '/por/rclist.csp'):
        print(f"TWFID has been captured: {flow.request.cookies.get('TWFID')}")
        print("Interrupt the connection!")
        flow.kill()
