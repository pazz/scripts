#!/usr/bin/python
# This is a half-ready script to scrape dict.leo.org
# Todo:
#  - sanitize REs in case of no results (there should be one big re and no chain of untested ones..)
#  - pydocs
#  - scrape more stuff (defs/pronunciation)

import re
import httplib
import argparse
class Leo:
    def lookup(self,what):
        c = httplib.HTTPConnection('dict.leo.org')
        c.request("GET","/ende?search=%s"%what)
        r = c.getresponse()
        #TODO r.status test!
        content = r.read()
        c.close()

        trash = ['<A.*?>','</A.*?>',
                 '<B.*?>','</B.*?>',
                 '<small.*?>','</small.*?>',
                 '<span.*?>','</span.*?>',
                 '<i.*?>','</i.*?>',
                 '&#160;',
                 '<input.*?>',
                 '<br />',
                ]
        r = []
        table = (re.search('<table cellpadding=0 cellspacing=0 width="100%" id="results".*?>(.*?)</table>',content)).group()
        table = self.rmtags(trash,table).replace('&nbsp;','')
        directhits = re.search('<th colspan="3">(.*?)<th colspan="3">',table).group()
        hits = re.findall('<tr(.*?)</tr>',directhits)
        for h in hits:
            x = re.findall('<td.*?>(.*?)</td>',h)
            if len(x)==2:
                cc = self.rmtags([' \(\d+ of \d+\)'], x[1])
                r.append([cc])
            elif len(x)==5:
                i,e,j,d,k = tuple(x)
                e=re.sub('<sup>(.+?)</sup>',' (\\1) ',e)
                d=re.sub('<sup>(.+?)</sup>',' (\\1) ',d)
                r[-1].append((e.strip(),d.strip()))
        return r

    def rmtags(self,ss,r):
        for s in ss:
            r=re.sub(s,'',r)
        return r

class Interface:

    def __init__(self,l,en=True,ger=True,categories=False):
        (self.l, self.e, self.g,self.categories) = (l,en,ger,categories)

    def lookup(self,what):
        self.formatResult(self.l.lookup(what))

    def formatResult(self,r):
        """ pretty prints output according to cmdline switches"""
        w = self.terminal_size()[0]
        for c in r:
            if self.categories:
                print "<"+'-'*20+c[0]+'-'*20+'>'
            wl = (w-3)/2
            for (en,ger) in c[1:]:
                if self.g == self.e: #print both if none is given explicitly
                    print en.ljust(wl)+" - "+ger.rjust(w-wl-3)
                elif self.g:
                    print ger
                elif self.e:
                    print en

    def ioctl_GWINSZ(self,fd): #### TABULATION FUNCTIONS
        try: ### Discover terminal width
            import fcntl, termios, struct, os
            cr = struct.unpack('hh',
            fcntl.ioctl(fd, termios.TIOCGWINSZ, '1234'))
        except:
            return None
        return cr

    def terminal_size(self):
        """ returns tuple of ints describing terms size """
        cr = self.ioctl_GWINSZ(0) or self.ioctl_GWINSZ(1) or self.ioctl_GWINSZ(2)
        if not cr:
            try:
                fd = os.open(os.ctermid(), os.O_RDONLY)
                cr = ioctl_GWINSZ(fd)
                os.close(fd)
            except:
                pass
            if not cr:
                try:
                    cr = (env['LINES'], env['COLUMNS'])
                except:
                    cr = (25, 80)
        return int(cr[1]), int(cr[0])


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument('what', metavar='word', nargs=1)
    parser.add_argument('-e', action='store_true')
    parser.add_argument('-g', action='store_true')
    parser.add_argument('-c', action='store_true')
    args = parser.parse_args()

    L=Leo()
    I=Interface(L,en=args.e,ger=args.g,categories=args.c)
    if args.what:
        I.lookup(args.what[0])
