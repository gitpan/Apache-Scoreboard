#include "modules/perl/mod_perl.h"
#include "scoreboard.h"

typedef struct {
    short_score record;
} Apache__short_score;

typedef Apache__short_score * Apache__ShortScore;

typedef struct {
    parent_score record;
} Apache__parent_score;

typedef Apache__parent_score * Apache__ParentScore;

typedef scoreboard * Apache__Scoreboard;

#define short_score_status(s) s->record.status
#define short_score_access_count(s) s->record.access_count
#define short_score_bytes_served(s) s->record.bytes_served
#define short_score_my_access_count(s) s->record.my_access_count
#define short_score_my_bytes_served(s) s->record.my_bytes_served
#define short_score_conn_bytes(s) s->record.conn_bytes
#define short_score_conn_count(s) s->record.conn_count
#define short_score_client(s) s->record.client
#define short_score_request(s) s->record.request

#define parent_score_pid(s) s->record.pid

MODULE = Apache::Scoreboard   PACKAGE = Apache::Scoreboard

BOOT:
{
    HV *stash = gv_stashpv("Apache::Constants", TRUE);
    (void)newCONSTSUB(stash, "HARD_SERVER_LIMIT", 
		      newSViv(HARD_SERVER_LIMIT));
}

Apache::Scoreboard
image(CLASS)
    SV *CLASS

    CODE:
    if (ap_exists_scoreboard_image()) {
	RETVAL = ap_scoreboard_image;
	ap_sync_scoreboard_image();
    }

    OUTPUT:
    RETVAL

Apache::ShortScore
servers(image, idx)
    Apache::Scoreboard image
    int idx

    CODE:
    RETVAL = (Apache__ShortScore )safemalloc(sizeof(*RETVAL));
    RETVAL->record = image->servers[idx];

    OUTPUT:
    RETVAL

Apache::ParentScore
parent(image, idx)
    Apache::Scoreboard image
    int idx

    CODE:
    RETVAL = (Apache__ParentScore )safemalloc(sizeof(*RETVAL));
    RETVAL->record = image->parent[idx];

    OUTPUT:
    RETVAL

MODULE = Apache::Scoreboard   PACKAGE = Apache::ShortScore   PREFIX = short_score_

void
DESTROY(self)
    Apache::ShortScore self

    CODE:
    safefree(self);

unsigned char
short_score_status(self)
    Apache::ShortScore self

unsigned long
short_score_access_count(self)
    Apache::ShortScore self

unsigned long
short_score_bytes_served(self)
    Apache::ShortScore self

unsigned long
short_score_my_access_count(self)
    Apache::ShortScore self

unsigned long
short_score_my_bytes_served(self)
    Apache::ShortScore self

unsigned long
short_score_conn_bytes(self)
    Apache::ShortScore self

unsigned short
short_score_conn_count(self)
    Apache::ShortScore self

char *
short_score_client(self)
    Apache::ShortScore self

char *
short_score_request(self)
    Apache::ShortScore self

MODULE = Apache::Scoreboard   PACKAGE = Apache::ParentScore   PREFIX = parent_score_

void
DESTROY(self)
    Apache::ParentScore self

    CODE:
    safefree(self);

pid_t
parent_score_pid(self)
    Apache::ParentScore self

