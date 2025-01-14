#define Uses_TView
#define Uses_TButton
#define Uses_TRect
#define Uses_TStatusLine
#define Uses_TStaticText
#define Uses_TLabel
#define Uses_TStatusDef
#define Uses_TStatusItem
#define Uses_TCheckBoxes
#define Uses_TRadioButtons
#define Uses_TScroller
#define Uses_TScrollBar
#define Uses_TIndicator
#define Uses_TInputLine
#define Uses_TEditor
#define Uses_TKeys
#define Uses_MsgBox
#define Uses_fpstream
#define Uses_TEvent
#define Uses_TDeskTop
#define Uses_TApplication
#define Uses_TWindow
#define Uses_TEditWindow
#define Uses_TDialog
#define Uses_TScreen
#define Uses_TSItem
#define Uses_TMenu
#define Uses_TMenuItem
#define Uses_TMenuBar
#define Uses_TSubMenu

#include <tvision/tv.h>

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

static int initialized = 0;
CV *cv_on_idle = 0;
CV *cv_handleEvent = 0;
CV *cv_onCommand = 0;

static inline TWindow* sv2tv_h(SV *sv) {
    // SvTYPE(SvRV(SV*)) === SVt_PVHV    Hash
    HV *hv = (HV*) SvRV(sv);
    SV** f = hv_fetch(hv, "obj", 3, 0);
    if (!f)
	croak("obj key does not contain tvision object");
    TWindow* w = *((TWindow**) SvPV_nolen(*f));
    return w;
}
static inline TWindow* sv2tv_a(SV *sv) {
    // SvTYPE(SvRV(SV*)) === SVt_PVAV    Array
    AV *av = (AV*) SvRV(sv);
    SV** f = av_fetch(av, 0, 0);
    if (!f)
	croak("self[0] does not contain tvision object");
    TWindow* w = *((TWindow**) SvPV_nolen(*f));
    return w;
}
#define sv2tv_s(sv,type) *((type**) SvPV_nolen(SvRV(sv)))
#define new_tv_a(w, pkg) \
    AV *self = newAV(); \
    av_store(self, 0, newSVpvn((const char *)&w, sizeof(w))); \
    SV *rself = newRV_inc((SV*) self); \
    sv_bless(rself, gv_stashpv(pkg, GV_ADD))
#define new_tvobj_a(self, w, pkg) \
    av_store(self, 0, newSVpvn((const char *)&w, sizeof(w))); \
    SV *rself = newRV_inc((SV*) self); \
    sv_bless(rself, gv_stashpv(pkg, GV_ADD))


class TVApp : public TApplication {
public:
    TVApp();
    static TStatusLine *initStatusLine( TRect r );
    static TMenuBar *initMenuBar( TRect r );
    virtual void handleEvent(TEvent& Event);
    virtual void getEvent(TEvent& event);
    virtual void idle();              // Updates heap and clock views
private:
    //void aboutDlgBox();               // "About" box
    //void printEvent(const TEvent &);
    //void chBackground();              // Background pattern
    //void openFile( const char *fileSpec );  // File Viewer
    //void changeDir();                 // Change directory
    //void mouse();                     // Mouse control dialog box
    //void colors();                    // Color control dialog box
    //void outOfMemory();               // For validView() function
    //void loadDesktop(fpstream& s);    // Load and restore the
    //void retrieveDesktop();           //  previously saved desktop
    //void storeDesktop(fpstream& s);   // Store the current desktop
    //void saveDesktop();               //  in a resource file
};
TVApp *tapp = NULL;
TVApp::TVApp() :
    TProgInit( &TVApp::initStatusLine,
               &TVApp::initMenuBar,
               &TVApp::initDeskTop )
{
}

void TVApp::idle() {
    TProgram::idle();
        //eval_pv("$::r++\n", TRUE);
        //eval_pv("TVision::fefe()", TRUE);
	//call_pv("TVision::fefe",0);
    if (cv_on_idle) {
	dSP;
	PUSHMARK(SP);
	PUTBACK;
	//call_pv("TVision::fefe", G_DISCARD|G_NOARGS);
	call_sv((SV*)cv_on_idle, G_DISCARD);
    }
}

void TVApp::handleEvent(TEvent& event) {
    TApplication::handleEvent(event);
    if (cv_handleEvent) {
	dSP;
	PUSHMARK(SP);
	PUTBACK;
	call_sv((SV*)cv_handleEvent, G_DISCARD);
    }
}

void TVApp::getEvent(TEvent &event) {
    TApplication::getEvent(event);
    switch (event.what) {
    case evCommand:
	if (cv_onCommand) {
	    dSP;
	    PUSHMARK(SP);
            EXTEND(SP, 2);
            PUSHs(sv_2mortal(newSViv(event.message.command)));
            PUSHs(sv_2mortal(newSViv(event.message.infoLong)));
	    PUTBACK;
	    call_sv((SV*)cv_onCommand, G_DISCARD);
	}
	if (event.message.command == 1) { }
	else if (event.message.command == 2) { }
	break;
    case evMouseDown:
	if (event.mouse.buttons == mbRightButton)
	    event.what = evNothing;
	break;
    case evMouseUp:
	break;
    case evMouseMove:
	break;
    case evMouseAuto:
	break;
    case evMouseWheel:
	break;
    case evKeyDown:
	break;
    case evBroadcast:
	break;
    }
}

TStatusLine *TVApp::initStatusLine( TRect r ) {
    printf("TVApp::initStatusLine\n");
    r.a.y = r.b.y - 1;

    return (new TStatusLine( r,
      *new TStatusDef( 0, 50 ) +
        *new TStatusItem( "~F1~ Help", kbF1, cmHelp ) +
        *new TStatusItem( "~Alt-X~ Exit", kbAltX, cmQuit ) +
        *new TStatusItem( 0, kbShiftDel, cmCut ) +
        *new TStatusItem( 0, kbCtrlIns, cmCopy ) +
        *new TStatusItem( 0, kbShiftIns, cmPaste ) +
        *new TStatusItem( 0, kbAltF3, cmClose ) +
        *new TStatusItem( 0, kbF10, cmMenu ) +
        *new TStatusItem( 0, kbF5, cmZoom ) +
        *new TStatusItem( 0, kbCtrlF5, cmResize ) +
      *new TStatusDef( 50, 0xffff ) +
        *new TStatusItem( "Howdy", kbF1, cmHelp )
        )
    );
}

const int
  hcCancelBtn            = 35,
  hcFCChDirDBox          = 37,
  hcFChangeDir           = 15,
  hcFDosShell            = 16,
  hcFExit                = 17,
  hcFOFileOpenDBox       = 31,
  hcFOFiles              = 33,
  hcFOName               = 32,
  hcFOOpenBtn            = 34,
  hcFOpen                = 14,
  hcFile                 = 13,
  hcNocontext            = 0,
  hcOCColorsDBox         = 39,
  hcOColors              = 28,
  hcOMMouseDBox          = 38,
  hcOMouse               = 27,
  hcORestoreDesktop      = 30,
  hcOSaveDesktop         = 29,
  hcOpenBtn              = 36,
  hcOptions              = 26,
  hcPuzzle               = 3,
  hcSAbout               = 8,
  hcSAsciiTable          = 11,
  hcSystem               = 7,
  hcViewer               = 2,
  hcWCascade             = 22,
  hcWClose               = 25,
  hcWNext                = 23,
  hcWPrevious            = 24,
  hcWSizeMove            = 19,
  hcWTile                = 21,
  hcWZoom                = 20,
  hcWindows              = 18;

const int cmAboutCmd    = 100;
const int cmOpenCmd     = 105;
const int cmChDirCmd    = 106;
const int cmMouseCmd    = 108;
const int cmSaveCmd     = 110;
const int cmRestoreCmd  = 111;
const int cmEventViewCmd= 112;


TMenuBar *TVApp::initMenuBar(TRect r) {
    TSubMenu& sub1 =
      *new TSubMenu( "~\xf0~", 0, hcSystem ) +
        *new TMenuItem( "~A~bout...", cmAboutCmd, kbNoKey, hcSAbout ) +
         newLine() +
        *new TMenuItem( "~E~vent Viewer", cmEventViewCmd, kbAlt0, hcNoContext, "Alt-0" );

    TSubMenu& sub2 =
      *new TSubMenu( "~F~ile", 0, hcFile ) +
        *new TMenuItem( "~O~pen...", cmOpenCmd, kbF3, hcFOpen, "F3" ) +
        *new TMenuItem( "~C~hange Dir...", cmChDirCmd, kbNoKey, hcFChangeDir ) +
         newLine() +
        *new TMenuItem( "~D~OS Shell", cmDosShell, kbNoKey, hcFDosShell ) +
        *new TMenuItem( "E~x~it", cmQuit, kbAltX, hcFExit, "Alt-X" );

    TSubMenu& sub3 =
      *new TSubMenu( "~W~indows", 0, hcWindows ) +
        *new TMenuItem( "~R~esize/move", cmResize, kbCtrlF5, hcWSizeMove, "Ctrl-F5" ) +
        *new TMenuItem( "~Z~oom", cmZoom, kbF5, hcWZoom, "F5" ) +
        *new TMenuItem( "~N~ext", cmNext, kbF6, hcWNext, "F6" ) +
        *new TMenuItem( "~C~lose", cmClose, kbAltF3, hcWClose, "Alt-F3" ) +
        *new TMenuItem( "~T~ile", cmTile, kbNoKey, hcWTile ) +
        *new TMenuItem( "C~a~scade", cmCascade, kbNoKey, hcWCascade );

    TSubMenu& sub4 =
      *new TSubMenu( "~O~ptions", 0, hcOptions ) +
        *new TMenuItem( "~M~ouse...", cmMouseCmd, kbNoKey, hcOMouse ) +
        (TMenuItem&) (
            *new TSubMenu( "~D~esktop", 0 ) +
            *new TMenuItem( "~S~ave desktop", cmSaveCmd, kbNoKey, hcOSaveDesktop ) +
            *new TMenuItem( "~R~etrieve desktop", cmRestoreCmd, kbNoKey, hcORestoreDesktop )
        );

    r.b.y =  r.a.y + 1;
    return (new TMenuBar( r, sub1 + sub2 + sub3 + sub4 ) );
}


MODULE=TVision::TApplication PACKAGE=TVision::TApplication

SV* new()
    CODE:
	tapp = new TVApp();
	new_tv_a(tapp,"TVision::TApplication");
        RETVAL = rself;
        // RETVAL = get_sv("TVision::TApplication::the_app", GV_ADD);
	//do_sv_dump(0, PerlIO_stderr(), RETVAL, 0, 10, 0,0);
    OUTPUT:
	RETVAL

SV* deskTop(TVApp *tapp)
    CODE:
	TDeskTop *w = tapp->deskTop;
	new_tv_a(w,"TVision::TDeskTop");
        RETVAL = rself;
    OUTPUT:
	RETVAL

void run(TVApp *tapp)
    CODE:
	tapp->run();

void on_idle(SV *self, CV *c = 0)
    CODE:
        cv_on_idle = c;

void handleEvent(SV *self, CV *c = 0)
    CODE:
        cv_handleEvent = c;

void onCommand(SV *self, CV *c = 0)
    CODE:
        cv_onCommand = c;
	printf("cv_onCommand=%016X\n", cv_onCommand);

MODULE=TVision::TDialog PACKAGE=TVision::TDialog

TDialog* new(int _ax, int ay, int bx, int by, char *title)
    CODE:
        RETVAL = new TDialog(TRect(_ax,ay,bx,by),title);
    OUTPUT:
	RETVAL

MODULE=TVision::TLabel PACKAGE=TVision::TLabel

TLabel* new(int _ax, int ay, int bx, int by, char *text, SV *view)
    CODE:
	TView *v = (TView*)sv2tv_a(view);
        RETVAL = new TLabel(TRect(_ax,ay,bx,by),text,v);
    OUTPUT:
	RETVAL

MODULE=TVision::TStaticText PACKAGE=TVision::TStaticText

TStaticText* new(int _ax, int ay, int bx, int by, char *text)
    CODE:
        RETVAL = new TStaticText(TRect(_ax,ay,bx,by),text);
    OUTPUT:
	RETVAL

MODULE=TVision::TButton PACKAGE=TVision::TButton
SV* _new_h(int _ax, int ay, int bx, int by, char *title, int cmd, int flags)
    CODE:
	TButton *w = new TButton(TRect(_ax,ay,bx,by),title,cmd,flags);
        HV *self = newHV();
        hv_store(self, "num", 3, newSViv(cmd), 0);
        hv_store(self, "obj", 3, newSVpvn((const char *)&w, sizeof(w)), 0);
        RETVAL = newRV_inc((SV*) self);
        sv_bless(RETVAL, gv_stashpv("TVision::TButton", GV_ADD));
    OUTPUT:
	RETVAL

TButton* _new_a(int _ax, int ay, int bx, int by, char *title, int cmd, int flags)
    CODE:
        RETVAL = new TButton(TRect(_ax,ay,bx,by),title,cmd,flags);
    OUTPUT:
	RETVAL

void setTitle(TButton *w, char *title)
    CODE:
	delete w->title;
	w->title = new char[strlen(title)+1];
	strcpy((char*)w->title,title);
	w->draw();

MODULE=TVision::TGroup PACKAGE=TVision::TGroup

void insert(TGroup *w, TWindow *what)
    CODE:
	w->insert(what);

MODULE=TVision::TView PACKAGE=TVision::TView

void locate(TView *w, int _ax, int ay, int bx, int by)
    CODE:
	TRect r(_ax,ay,bx,by);
	w->locate(r);

void blockCursor(TView* w)
    CODE:
	w->blockCursor();

void normalCursor(TView* w)
    CODE:
	w->normalCursor();

void resetCursor(TView* w)
    CODE:
	w->resetCursor();

void setCursor(TView *w, int x, int y)
    CODE:
	w->setCursor(x,y);

void showCursor(TView* w)
    CODE:
	w->showCursor();

void drawCursor(TView* w)
    CODE:
	w->drawCursor();

void focus(TView* w)
    CODE:
	w->focus();

MODULE=TVision::TInputLine PACKAGE=TVision::TInputLine

TInputLine* new(int _ax, int ay, int bx, int by, int limit)
    CODE:
        RETVAL = new TInputLine(TRect(_ax,ay,bx,by),limit);
    OUTPUT:
	RETVAL

void setData(TInputLine *til, char *data)
    CODE:
	til->setData(data);

char *getData(TInputLine *til)
    CODE:
	char data[2048]; // OMG2
	til->getData(data);
	RETVAL=data;
    OUTPUT:
	RETVAL

MODULE=TVision::TCheckBoxes PACKAGE=TVision::TCheckBoxes
SV* new(int _ax, int ay, int bx, int by, AV *_items)
    CODE:
        int cnt = av_count(_items);
	//printf("items=%d\n",cnt);
        TSItem *tsit = 0;
	for (int i=cnt-1; i>=0; i--) {
	    SV **sv = av_fetch(_items, i, 0);
	    //printf("i=%d s=%s\n", i, SvPV_nolen(*sv));
	    TSItem *n = new TSItem(SvPV_nolen(*sv), tsit);
	    tsit = n;
	}
	TCheckBoxes *w = new TCheckBoxes(TRect(_ax,ay,bx,by), tsit);
	new_tv_a(w,"TVision::TCheckBoxes");
        RETVAL = rself;
    OUTPUT:
	RETVAL

MODULE=TVision::TRadioButtons PACKAGE=TVision::TRadioButtons
SV* new(int _ax, int ay, int bx, int by, AV *_items)
    CODE:
        int cnt = av_count(_items);
	//printf("items=%d\n",cnt);
        TSItem *tsit = 0;
	for (int i=cnt-1; i>=0; i--) {
	    SV **sv = av_fetch(_items, i, 0);
	    //printf("i=%d s=%s\n", i, SvPV_nolen(*sv));
	    TSItem *n = new TSItem(SvPV_nolen(*sv), tsit);
	    tsit = n;
	}
	TRadioButtons *w = new TRadioButtons(TRect(_ax,ay,bx,by), tsit);
	new_tv_a(w,"TVision::TRadioButtons");
        RETVAL = rself;
    OUTPUT:
	RETVAL

MODULE=TVision::TScrollBar PACKAGE=TVision::TScrollBar

TScrollBar* new(int _ax, int ay, int bx, int by)
    CODE:
        RETVAL = new TScrollBar(TRect(_ax,ay,bx,by));
    OUTPUT:
	RETVAL

MODULE=TVision::TIndicator PACKAGE=TVision::TIndicator
SV* new(int _ax, int ay, int bx, int by)
    CODE:
	TIndicator *w = new TIndicator(TRect(_ax,ay,bx,by));
	new_tv_a(w,"TVision::TIndicator");
        RETVAL = rself;
    OUTPUT:
	RETVAL

MODULE=TVision::TEditor PACKAGE=TVision::TEditor

TEditor* new(int _ax, int ay, int bx, int by, TScrollBar *sb1, TScrollBar *sb2, TIndicator *ind, int n)
    CODE:
	if (sb1==NULL){printf("ok got NULL\n");}
        RETVAL = new TEditor(TRect(_ax,ay,bx,by),sb1,sb2,ind, n);
    OUTPUT:
	RETVAL

MODULE=TVision::TWindow PACKAGE=TVision::TWindow

TWindow* new(int _ax, int ay, int bx, int by, char *title, int num)
    CODE:
        RETVAL = new TWindow(TRect(_ax,ay,bx,by),title,num);
    OUTPUT:
	RETVAL

MODULE=TVision::TMenu PACKAGE=TVision::TMenu

TMenu* new()
    CODE:
        RETVAL = new TMenu();
    OUTPUT:
	RETVAL

MODULE=TVision::TSubMenu PACKAGE=TVision::TSubMenu
SV* new(char *nm, int key, int helpCtx = hcNoContext)
    CODE:
	// TSubMenu(TStringView nm, TKey key, ushort helpCtx = hcNoContext);
	TSubMenu *w = new TSubMenu(TStringView(nm),key,helpCtx);
	new_tv_a(w,"TVision::TSubMenu");
        RETVAL = rself;
    OUTPUT:
	RETVAL

MODULE=TVision::TMenuBar PACKAGE=TVision::TMenuBar
SV* new(int _ax, int ay, int bx, int by, SV *TMenu_or_TSubMenu)
    CODE:
        TRect r(_ax,ay,bx,by);
	TMenuBar *w;
	if (sv_isa(TMenu_or_TSubMenu, "TVision::TMenu")) {
	    TMenu *m = *((TMenu**) SvPV_nolen(TMenu_or_TSubMenu));
	    w = new TMenuBar(r,m);
	} else if (sv_isa(TMenu_or_TSubMenu, "TVision::TSubMenu")) {
	    TSubMenu sm = **((TSubMenu**) SvPV_nolen(TMenu_or_TSubMenu));
	    w = new TMenuBar(r,sm);
	} else {
	    croak("wrong inheritance in TVision::TMenuBar::new");
	}
	new_tv_a(w,"TVision::TMenuBar");
        RETVAL = rself;
    OUTPUT:
	RETVAL

#if 0
MODULE=TVision::TEditWindow PACKAGE=TVision::TEditWindow
SV* new(int _ax, int ay, int bx, int by, char *title, int num)
    CODE:
        TRect r(_ax,ay,bx,by);
	TEditWindow *w = new TEditWindow(r,title,num);
	new_tv_a(w,"TVision::TEditWindow");
        RETVAL = rself;
    OUTPUT:
	RETVAL


#endif

MODULE=TVision::TDeskTop PACKAGE=TVision::TDeskTop

void insert_obsoleted(SV *self, SV *what)
    CODE:
	TDeskTop* td = sv2tv_s(self,TDeskTop);
        SV *sv = SvRV(what);
        TWindow* w = *((TWindow**) SvPV_nolen(sv));
	td->insert(w);

MODULE=TVision PACKAGE=TVision

BOOT:
    TObject *tvnull = NULL;
    new_tv_a(tvnull, "TVision");
    sv_setsv(get_sv("TVision::NULL", GV_ADD), rself);
