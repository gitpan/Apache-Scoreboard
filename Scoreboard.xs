#include "modules/perl/mod_perl.h"
#include "scoreboard.h"

#define REMOTE_SCOREBOARD_TYPE "application/x-apache-scoreboard"
#ifndef HZ
#define HZ 100
#endif

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

static char status_flags[SERVER_NUM_STATUS];

#define SIZE16 2

static void pack16(unsigned char *s, int p)
{
    short ashort = htons(p);
    Move(&ashort, s, SIZE16, unsigned char);
}

static unsigned short unpack16(unsigned char *s)
{
    unsigned short ashort;
    Copy(s, &ashort, SIZE16, char);
    return ntohs(ashort);
}

static void status_flags_init(void)
{
    status_flags[SERVER_DEAD] = '.';
    status_flags[SERVER_READY] = '_';
    status_flags[SERVER_STARTING] = 'S';
    status_flags[SERVER_BUSY_READ] = 'R';
    status_flags[SERVER_BUSY_WRITE] = 'W';
    status_flags[SERVER_BUSY_KEEPALIVE] = 'K';
    status_flags[SERVER_BUSY_LOG] = 'L';
    status_flags[SERVER_BUSY_DNS] = 'D';
    status_flags[SERVER_GRACEFUL] = 'G';
}

MODULE = Apache::Scoreboard   PACKAGE = Apache::Scoreboard

BOOT:
{
    HV *stash = gv_stashpv("Apache::Constants", TRUE);
    newCONSTSUB(stash, "HARD_SERVER_LIMIT",
		newSViv(HARD_SERVER_LIMIT));
    stash = gv_stashpv("Apache::Scoreboard", TRUE);
    newCONSTSUB(stash, "REMOTE_SCOREBOARD_TYPE",
		newSVpv(REMOTE_SCOREBOARD_TYPE, 0));
    status_flags_init();
}

int
send(r)
    Apache r

    PREINIT:
    int i, psize, ssize, tsize;
    char buf[SIZE16*2];
    char *ptr = buf;

    CODE:
    ap_sync_scoreboard_image();
    for (i=0; i<HARD_SERVER_LIMIT; i++) {
	if (!ap_scoreboard_image->parent[i].pid) {
	    break;
	}
    }
    RETVAL = OK;
    psize = i * sizeof(parent_score);
    ssize = i * sizeof(short_score);
    tsize = psize + ssize + sizeof(global_score) + sizeof(buf);

    pack16(ptr, psize);
    ptr += SIZE16;
    pack16(ptr, ssize);

    ap_set_content_length(r, tsize);
    r->content_type = REMOTE_SCOREBOARD_TYPE;
    ap_send_http_header(r);

    if (!r->header_only) {
	ap_rwrite(&buf[0], sizeof(buf), r);
	ap_rwrite(&ap_scoreboard_image->parent[0], psize, r);
	ap_rwrite(&ap_scoreboard_image->servers[0], ssize, r);
	ap_rwrite(&ap_scoreboard_image->global, sizeof(global_score), r);
    }

    OUTPUT:
    RETVAL

Apache::Scoreboard
thaw(CLASS, packet)
    SV *CLASS
    SV *packet

    PREINIT:
    int psize, ssize;
    char *ptr;

    CODE:
    if (!ap_scoreboard_image) {
	ap_scoreboard_image = 
	  (scoreboard *)safemalloc(sizeof(*ap_scoreboard_image));
	memset((char *)ap_scoreboard_image, 0, sizeof(*ap_scoreboard_image));
    }

    RETVAL = ap_scoreboard_image;
    ptr = SvPVX(packet);
    psize = unpack16(ptr);
    ptr += SIZE16;
    ssize = unpack16(ptr);
    ptr += SIZE16;

    Move(ptr, &RETVAL->parent[0], psize, char);
    ptr += psize;
    Move(ptr, &RETVAL->servers[0], ssize, char);
    ptr += ssize;
    Move(ptr, &RETVAL->global, sizeof(global_score), char);

    OUTPUT:
    RETVAL

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

void
times(self)
    Apache::ShortScore self

    PPCODE:
    if (GIMME == G_ARRAY) {
	/* same return values as CORE::times() */
	EXTEND(sp, 4);
	PUSHs(sv_2mortal(newSViv(self->record.times.tms_utime)));
	PUSHs(sv_2mortal(newSViv(self->record.times.tms_stime)));
	PUSHs(sv_2mortal(newSViv(self->record.times.tms_cutime)));
	PUSHs(sv_2mortal(newSViv(self->record.times.tms_cstime)));
    }
    else {
#ifdef _SC_CLK_TCK
	float tick = sysconf(_SC_CLK_TCK);
#else
	float tick = HZ;
#endif
	/* cpu %, same value mod_status displays */
	float RETVAL = (self->record.times.tms_utime +
			self->record.times.tms_stime +
			self->record.times.tms_cutime +
			self->record.times.tms_cstime);
	XPUSHs(sv_2mortal(newSVnv((double)RETVAL/tick)));
    }

void
start_time(self)
    Apache::ShortScore self

    ALIAS:
    stop_time = 1

    PREINIT:
    struct timeval tp;

    PPCODE:
    tp = (XSANY.any_i32 == 0) ? 
         self->record.start_time : self->record.stop_time;

    /* do the same as Time::HiRes::gettimeofday */
    if (GIMME == G_ARRAY) {
	EXTEND(sp, 2);
	PUSHs(sv_2mortal(newSViv(tp.tv_sec)));
	PUSHs(sv_2mortal(newSViv(tp.tv_usec)));
    } 
    else {
	EXTEND(sp, 1);
	PUSHs(sv_2mortal(newSVnv(tp.tv_sec + (tp.tv_usec / 1000000.0))));
    }

long
req_time(self)
    Apache::ShortScore self

    CODE:
    /* request time in millseconds, same value mod_status displays  */
    if (self->record.start_time.tv_sec == 0L &&
	self->record.start_time.tv_usec == 0L) {
	RETVAL = 0L;
    }
    else {
	RETVAL =
	  ((self->record.stop_time.tv_sec - 
	    self->record.start_time.tv_sec) * 1000) +
	      ((self->record.stop_time.tv_usec - 
		self->record.start_time.tv_usec) / 1000);
    }
    if (RETVAL < 0L) {
	RETVAL = 0L;
    }

    OUTPUT:
    RETVAL

SV *
short_score_status(self)
    Apache::ShortScore self

    CODE:
    RETVAL = newSV(0);
    sv_setnv(RETVAL, (double)self->record.status);
    sv_setpvf(RETVAL, "%c", status_flags[self->record.status]);
    SvNOK_on(RETVAL); /* dual-var */ 

    OUTPUT:
    RETVAL

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

