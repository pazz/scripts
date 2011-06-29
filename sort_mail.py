#!/usr/bin/python

#this is based on http://notmuchmail.org/pipermail/notmuch/2011/003976.html

import os
import logging
import time
import notmuch

LOGLEVEL = logging.INFO

_tags = []
start_time = time.time()

def _list(name, tag):
        _tags.append( ('to:%s'%name, ['list', tag]) )

def tag(filter, *tags):
        _tags.append( (filter, tags) )

#send by me
tag('from:Patrick Totzke', 'sent')

#lists
_list('peergroup', 'peergroup')
_list('urwid', 'urwid')
_list('notmuch', 'notmuch')
_list('atp-vim-list@lists.sourceforge.net', 'atp')
_list('sup-talk@rubyforge.org', 'sup')
_list('sup-devel@rubyforge.org', 'sup')

#societies
tag('from:foosoc.ed@gmail.com or from:GT Silber', 'soc','foo')
tag('from:wols', 'soc','wols')

#UoE
tag('folder:uoe/Call4Papers', 'C4P')
_list('lfcs-interest@inf.ed.ac.uk', 'lfcs')
_list('students@inf.ed.ac.uk', 'students')
_list('research-degree-students@inf.ed.ac.uk', 'gradschool')
_list('sicsa-students@sicsa.ac.uk', 'sicsa')
_list('automata-team@fit.vutbr.cz', 'automata')
_list('agda-course@inf.ed.ac.uk', 'agda')


#############################################
# do teh monkey
def tag_message(msg, *tags):
    msg.freeze()
    for tag in tags:
        if tag[0] == '+':
                msg.add_tag(tag[1:])
        elif tag[0] == '-':
                msg.remove_tag(tag[1:])
        else:
                msg.add_tag(tag)
    msg.thaw()

def tag_search(db, search, *tags):
    q = notmuch.Query(db, search)
    count = 0
    for msg in q.search_messages():
        count += 1
        tag_message(msg, *tags)
    if count > 0:
            logging.debug('Tagging %d messages with (%s)' % (count, ' '.join(tags)))

db = notmuch.Database(mode=notmuch.Database.MODE.READ_WRITE)
logging.basicConfig(level=LOGLEVEL)
# Freeze new messages
q_new = notmuch.Query(db, 'tag:new')
n_msgs = 0
for msg in q_new.search_messages():
    msg.freeze()
    n_msgs += 1


# Tag things
for filter, tags in _tags:
    tag_search(db, '%s and tag:new' % filter, *tags)

# Ignore things I sent
tag_search(db, 'tag:new and tag:sent', '-unseen', '-new', '-unread', '-killed')

# Update killtag
for msg in q_new.search_messages():
    q = notmuch.Query(db, 'tag:killed and thread:%s' % msg.get_thread_id())
    if len(list(q.search_messages())) > 0:
        logging.debug('killing %s' % msg.get_message_id())
        tag_message(msg, 'killed', '-new')

# Tag remaining new items for inbox
tag_search(db, 'tag:new', '+inbox', '-new')

# Thaw new messages
for msg in q_new.search_messages():
        msg.thaw()

end_time = time.time()
logging.info('Sorted %d messages in %1.2f seconds' % (n_msgs, end_time - start_time))
pic = '/usr/share/icons/Human/scalable/emblems/emblem-mail.svg'
topic = '\"new mail\"'

#q = notmuch.Query(db, 'tag:inbox AND NOT tag:killed')
#count = q.count_messages()
#if count:
#    msg = '\"there are currently %d messages in your inbox\"'%count
#    notify_cmd="/usr/bin/notify-send -t 5 -i %s %s %s"%(pic, topic, msg)
#    os.system(notify_cmd)
