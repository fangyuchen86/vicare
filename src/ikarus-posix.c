/*
  Part of: Vicare
  Contents: interface to POSIX functions
  Date: Sun Nov	 6, 2011

  Abstract

	Interface to POSIX functions.  For the full documentation of the
	functions in this module,  see the official Vicare documentation
	in Texinfo format.

  Copyright (C) 2011, 2012, 2013, 2014, 2015 Marco Maggi <marco.maggi-ipsu@poste.it>
  Copyright (C) 2006,2007,2008	Abdulaziz Ghuloum

  This program is  free software: you can redistribute	it and/or modify
  it under the	terms of the GNU General Public	 License as published by
  the Free Software Foundation, either	version 3 of the License, or (at
  your option) any later version.

  This program	is distributed in the  hope that it will  be useful, but
  WITHOUT   ANY	 WARRANTY;   without  even   the  implied   warranty  of
  MERCHANTABILITY  or FITNESS  FOR A  PARTICULAR PURPOSE.   See	 the GNU
  General Public License for more details.

  You  should have received  a copy  of the  GNU General  Public License
  along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/


/** --------------------------------------------------------------------
 ** Headers.
 ** ----------------------------------------------------------------- */

/* This causes inclusion of "pread".  (Marco Maggi; Nov 11, 2011) */
#define _GNU_SOURCE	1

#include "internals.h"
#ifdef HAVE_DIRENT_H
#  include <dirent.h>
#endif
#ifdef HAVE_FCNTL_H
#  include <fcntl.h>
#endif
#ifdef HAVE_GRP_H
#  include <grp.h>
#endif
#ifdef HAVE_MQUEUE_H
#  include <mqueue.h>
#endif
#ifdef HAVE_POLL_H
#  include <poll.h>
#endif
#ifdef HAVE_PWD_H
#  include <pwd.h>
#endif
#ifdef HAVE_SEMAPHORE_H
#  include <semaphore.h>
#endif
#ifdef HAVE_SIGNAL_H
#  include <signal.h>
#endif
#ifdef HAVE_STDINT_H
#  include <stdint.h>
#endif
#ifdef HAVE_TERMIOS_H
#  include <termios.h>
#endif
#ifdef HAVE_TIME_H
#  include <time.h>
#endif
#ifdef HAVE_UTIME_H
#  include <utime.h>
#endif
#ifdef HAVE_UNISTD_H
#  include <unistd.h>
#endif
#ifdef HAVE_SYS_IOCTL_H
#  include <sys/ioctl.h>
#endif
#ifdef HAVE_SYS_MMAN_H
#  include <sys/mman.h>
#endif
#ifdef HAVE_SYS_PARAM_H
#  include <sys/param.h>
#endif
#ifdef HAVE_SYS_RESOURCE_H
#  include <sys/resource.h>
#endif
#ifdef HAVE_SYS_STAT_H
#  include <sys/stat.h>
#endif
#ifdef HAVE_SYS_UTSNAME_H
#  include <sys/utsname.h>
#endif
#ifdef HAVE_SYS_TIME_H
#  include <sys/time.h>
#endif
#ifdef HAVE_SYS_TIMES_H
#  include <sys/times.h>
#endif
#ifdef HAVE_SYS_TYPES_H
#  include <sys/types.h>
#endif
#ifdef HAVE_SYS_UIO_H
#  include <sys/uio.h>
#endif
#ifdef HAVE_SYS_UN_H
#  include <sys/un.h>
#endif
#ifdef HAVE_SYS_WAIT_H
#  include <sys/wait.h>
#endif

#define SIZEOF_STRUCT_IN_ADDR		sizeof(struct in_addr)
#define SIZEOF_STRUCT_IN6_ADDR		sizeof(struct in6_addr)

/* process identifiers */
#define IK_PID_TO_NUM(pid)		IK_FIX(pid)
#define IK_NUM_TO_PID(pid)		IK_UNFIX(pid)

/* user identifiers */
#define IK_UID_TO_NUM(uid)		IK_FIX(uid)
#define IK_NUM_TO_UID(uid)		IK_UNFIX(uid)

/* group identifiers */
#define IK_GID_TO_NUM(gid)		IK_FIX(gid)
#define IK_NUM_TO_GID(gid)		IK_UNFIX(gid)

/* file descriptors */
#define IK_FD_TO_NUM(fd)		IK_FIX(fd)
#define IK_NUM_TO_FD(fd)		IK_UNFIX(fd)

/* interprocess signal numbers */
#define IK_SIGNUM_TO_NUM(signum)	IK_FIX(signum)
#define IK_NUM_TO_SIGNUM(signum)	IK_UNFIX(signum)

/* file access mode */
#define IK_FILEMODE_TO_NUM(filemode)	IK_FIX(filemode)
#define IK_NUM_TO_FILEMODE(filemode)	IK_UNFIX(filemode)

/* ------------------------------------------------------------------ */

static IK_UNUSED void
feature_failure_ (const char * funcname)
{
  ik_abort("called POSIX specific function, %s\n", funcname);
}

#define feature_failure(FN)     { feature_failure_(FN); return IK_VOID_OBJECT; }


/** --------------------------------------------------------------------
 ** Access to Scheme data structures.
 ** ----------------------------------------------------------------- */

#define VICARE_POSIX_STRUCT_TIMEVAL_TV_SEC	0
#define VICARE_POSIX_STRUCT_TIMEVAL_TV_USEC	1


/** --------------------------------------------------------------------
 ** Errno handling.
 ** ----------------------------------------------------------------- */

ikptr_t
ik_errno_to_code (void)
/* Negate the current errno value and convert it into a fixnum. */
{
  int negated_errno_code = - errno;
  return IK_FIX(negated_errno_code);
}
ikptr_t
ikrt_posix_strerror (ikptr_t negated_errno_code, ikpcb_t* pcb)
{
#ifdef HAVE_STRERROR
  int	 code = - IK_UNFIX(negated_errno_code);
  errno = 0;
  char * error_message = strerror(code);
  return errno? IK_FALSE_OBJECT : ika_bytevector_from_cstring(pcb, error_message);
#else
  feature_failure(__func__);
#endif
}


/** --------------------------------------------------------------------
 ** Operating system environment variables.
 ** ----------------------------------------------------------------- */

ikptr_t
ikrt_posix_getenv (ikptr_t bv, ikpcb_t* pcb)
{
#ifdef HAVE_GETENV
  char *  str = getenv(IK_BYTEVECTOR_DATA_CHARP(bv));
  return (str)? ika_bytevector_from_cstring(pcb, str) : IK_FALSE_OBJECT;
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_setenv (ikptr_t key, ikptr_t val, ikptr_t overwrite)
{
#ifdef HAVE_SETENV
  int	err = setenv(IK_BYTEVECTOR_DATA_CHARP(key),
		     IK_BYTEVECTOR_DATA_CHARP(val),
		     (overwrite != IK_FALSE_OBJECT));
  return (err)? IK_FALSE_OBJECT : IK_TRUE_OBJECT;
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_unsetenv (ikptr_t key)
{
#ifdef HAVE_UNSETENV
  char *	varname = IK_BYTEVECTOR_DATA_CHARP(key);
#if (1 == UNSETENV_HAS_RETURN_VALUE)
  int		rv = unsetenv(varname);
  return (0 == rv)? IK_TRUE_OBJECT : IK_FALSE_OBJECT;
#else
  unsetenv(varname);
  return IK_TRUE_OBJECT;
#endif
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_environ (ikpcb_t* pcb)
{
#ifdef HAVE_DECL_ENVIRON
  ikptr_t		s_list	= IK_NULL_OBJECT;
  ikptr_t		s_spine = IK_NULL_OBJECT;
  int		i;
  s_list = s_spine = ika_pair_alloc(pcb);
  pcb->root0 = &s_list;
  pcb->root1 = &s_spine;
  {
    for (i=0; environ[i];) {
      IK_ASS(IK_CAR(s_spine), ika_bytevector_from_cstring(pcb, environ[i]));
      IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_CAR_PTR(s_spine));
      if (environ[++i]) {
	IK_ASS(IK_CDR(s_spine), ika_pair_alloc(pcb));
	IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_CDR_PTR(s_spine));
	s_spine = IK_CDR(s_spine);
      } else
	IK_CDR(s_spine) = IK_NULL_OBJECT;
    }
  }
  pcb->root1 = NULL;
  pcb->root0 = NULL;
  return s_list;
#else
  feature_failure(__func__);
#endif
}


/** --------------------------------------------------------------------
 ** Process identifiers.
 ** ----------------------------------------------------------------- */

ikptr_t
ikrt_posix_getpid(void)
{
#ifdef HAVE_GETPID
  return IK_PID_TO_NUM(getpid());
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_getppid(void)
{
#ifdef HAVE_GETPPID
  return IK_PID_TO_NUM(getppid());
#else
  feature_failure(__func__);
#endif
}


/** --------------------------------------------------------------------
 ** Executing processes.
 ** ----------------------------------------------------------------- */

ikptr_t
ikrt_posix_system (ikptr_t command)
{
#ifdef HAVE_SYSTEM
  int		rv;
  errno = 0;
  rv	= system(IK_BYTEVECTOR_DATA_CHARP(command));
  return (0 <= rv)? IK_FIX(rv) : ik_errno_to_code();
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_fork (void)
{
#ifdef HAVE_FORK
  int	pid;
  errno = 0;
  pid	= fork();
  return (0 <= pid)? IK_PID_TO_NUM(pid) : ik_errno_to_code();
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_execv (ikptr_t filename_bv, ikptr_t argv_list)
{
#ifdef HAVE_EXECV
  char *  filename = IK_BYTEVECTOR_DATA_CHARP(filename_bv);
  int	  argc	   = ik_list_length(argv_list);
  char *  argv[1+argc];
  ik_list_to_argv(argv_list, argv);
  errno	  = 0;
  execv(filename, argv);
  /* If we are here: an error occurred. */
  return ik_errno_to_code();
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_execve (ikptr_t filename_bv, ikptr_t argv_list, ikptr_t envv_list)
{
#ifdef HAVE_EXECVE
  char *  filename = IK_BYTEVECTOR_DATA_CHARP(filename_bv);
  int	  argc = ik_list_length(argv_list);
  char *  argv[1+argc];
  int	  envc = ik_list_length(envv_list);
  char *  envv[1+envc];
  ik_list_to_argv(argv_list, argv);
  ik_list_to_argv(envv_list, envv);
  errno	 = 0;
  execve(filename, argv, envv);
  /* If we are here: an error occurred. */
  return ik_errno_to_code();
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_execvp (ikptr_t filename_bv, ikptr_t argv_list)
{
#ifdef HAVE_EXECVP
  char *  filename = IK_BYTEVECTOR_DATA_CHARP(filename_bv);
  int	  argc = ik_list_length(argv_list);
  char *  argv[1+argc];
  ik_list_to_argv(argv_list, argv);
  errno	 = 0;
  execvp(filename, argv);
  /* If we are here: an error occurred. */
  return ik_errno_to_code();
#else
  feature_failure(__func__);
#endif
}


/** --------------------------------------------------------------------
 ** Process exit status.
 ** ----------------------------------------------------------------- */

ikptr_t
ikrt_posix_waitpid (ikptr_t s_pid, ikptr_t s_options, ikpcb_t * pcb)
{
#ifdef HAVE_WAITPID
  int	status  = 0;
  int	options = IK_UNFIX(s_options);
  pid_t rv;
  errno	 = 0;
  rv	 = waitpid(IK_NUM_TO_PID(s_pid), &status, options);
  if ((0 == rv) && (WNOHANG == (WNOHANG & options))) {
    /* No child process exited. */
    return IK_FALSE;
  } else {
    return (0 <= rv)? ika_integer_from_int(pcb, status) : ik_errno_to_code();
  }
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_wait (ikpcb_t * pcb)
{
#ifdef HAVE_WAIT
  int	status;
  pid_t rv;
  errno	 = 0;
  rv	 = wait(&status);
  return (0 <= rv)? ika_integer_from_int(pcb, status) : ik_errno_to_code();
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_WIFEXITED (ikptr_t s_status)
{
#ifdef HAVE_WIFEXITED
  int	status = ik_integer_to_int(s_status);
  return (WIFEXITED(status))? IK_TRUE_OBJECT : IK_FALSE_OBJECT;
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_WEXITSTATUS (ikptr_t s_status, ikpcb_t * pcb)
{
#ifdef HAVE_WEXITSTATUS
  int	status = ik_integer_to_int(s_status);
  return ika_integer_from_int(pcb, WEXITSTATUS(status));
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_WIFSIGNALED (ikptr_t s_status)
{
#ifdef HAVE_WIFSIGNALED
  int	status = ik_integer_to_int(s_status);
  return (WIFSIGNALED(status))? IK_TRUE_OBJECT : IK_FALSE_OBJECT;
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_WTERMSIG (ikptr_t s_status, ikpcb_t * pcb)
{
#ifdef HAVE_WTERMSIG
  int	status = ik_integer_to_int(s_status);
  return ika_integer_from_int(pcb, WTERMSIG(status));
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_WCOREDUMP (ikptr_t s_status)
{
#ifdef HAVE_WCOREDUMP
  int	status = ik_integer_to_int(s_status);
  return (WCOREDUMP(status))? IK_TRUE_OBJECT : IK_FALSE_OBJECT;
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_WIFSTOPPED (ikptr_t s_status)
{
#ifdef HAVE_WIFSTOPPED
  int	status = ik_integer_to_int(s_status);
  return (WIFSTOPPED(status))? IK_TRUE_OBJECT : IK_FALSE_OBJECT;
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_WSTOPSIG (ikptr_t s_status, ikpcb_t * pcb)
{
#ifdef HAVE_WSTOPSIG
  int	status = ik_integer_to_int(s_status);
  return ika_integer_from_int(pcb, WSTOPSIG(status));
#else
  feature_failure(__func__);
#endif
}


/** --------------------------------------------------------------------
 ** Delivering interprocess signals.
 ** ----------------------------------------------------------------- */

ikptr_t
ikrt_posix_raise (ikptr_t s_signum)
{
#ifdef HAVE_RAISE
  int r = raise(IK_NUM_TO_SIGNUM(s_signum));
  return (0 == r)? IK_FIX(0) : ik_errno_to_code();
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_kill (ikptr_t s_pid, ikptr_t s_signum)
{
#ifdef HAVE_KILL
  pid_t pid    = IK_NUM_TO_PID(s_pid);
  int	signum = IK_NUM_TO_SIGNUM(s_signum);
  int	r = kill(pid, signum);
  return (0 == r)? IK_FIX(0) : ik_errno_to_code();
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_pause (void)
{
#ifdef HAVE_PAUSE
  pause();
  return IK_VOID_OBJECT;
#else
  feature_failure(__func__);
#endif
}


/** --------------------------------------------------------------------
 ** Miscellaneous stat functions.
 ** ----------------------------------------------------------------- */

#ifdef HAVE_STAT
static ikptr_t
fill_stat_struct (struct stat * S, ikptr_t D, ikpcb_t* pcb)
{
  pcb->root9 = &D;
  {
#if (4 == IK_SIZE_OF_VOIDP)
    /* 32-bit platforms */
    IK_ASS(IK_FIELD(D, 0), ika_integer_from_ulong(pcb, (ik_ulong)S->st_mode));
    IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_FIELD_PTR(D, 0));

    IK_ASS(IK_FIELD(D, 1), ika_integer_from_ulong(pcb, (ik_ulong)S->st_ino));
    IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_FIELD_PTR(D, 1));

    IK_ASS(IK_FIELD(D, 2), ika_integer_from_long (pcb, (long)S->st_dev));
    IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_FIELD_PTR(D, 2));

    IK_ASS(IK_FIELD(D, 3), ika_integer_from_ulong(pcb, (ik_ulong)S->st_nlink));
    IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_FIELD_PTR(D, 3));
    /**/
    IK_ASS(IK_FIELD(D, 4), ika_integer_from_ulong(pcb, (ik_ulong)S->st_uid));
    IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_FIELD_PTR(D, 4));

    IK_ASS(IK_FIELD(D, 5), ika_integer_from_ulong(pcb, (ik_ulong)S->st_gid));
    IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_FIELD_PTR(D, 5));

    IK_ASS(IK_FIELD(D, 6), ika_integer_from_ullong(pcb,(ik_ullong)S->st_size));
    IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_FIELD_PTR(D, 6));
    /**/
    IK_ASS(IK_FIELD(D, 7), ika_integer_from_long(pcb, (long)S->st_atime));
    IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_FIELD_PTR(D, 7));

#ifdef HAVE_STAT_ST_ATIM_TV_NSEC
    IK_ASS(IK_FIELD(D, 8), ika_integer_from_ulong(pcb, (ik_ulong)S->st_atim.tv_nsec));
    IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_FIELD_PTR(D, 8));
#elif (defined HAVE_STAT_ST_ATIMENSEC)
    IK_ASS(IK_FIELD(D, 8), ika_integer_from_ulong(pcb, (ik_ulong)S->st_atimensec));
    IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_FIELD_PTR(D, 8));
#else
    IK_ASS(IK_FIELD(D, 8), IK_FALSE_OBJECT);
#endif
    /**/
    IK_ASS(IK_FIELD(D, 9) , ika_integer_from_long(pcb, (long)S->st_mtime));
    IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_FIELD_PTR(D, 9));
#ifdef HAVE_STAT_ST_MTIM_TV_NSEC
    IK_ASS(IK_FIELD(D, 10), ika_integer_from_ulong(pcb, (ik_ulong)S->st_mtim.tv_nsec));
    IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_FIELD_PTR(D, 10));
#elif (defined HAVE_STAT_ST_MTIMENSEC)
    IK_ASS(IK_FIELD(D, 10), ika_integer_from_ulong(pcb, (ik_ulong)S->st_mtimensec));
    IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_FIELD_PTR(D, 10));
#else
    IK_ASS(IK_FIELD(D, 10), IK_FALSE_OBJECT);
#endif
    /**/
    IK_ASS(IK_FIELD(D, 11), ika_integer_from_long(pcb, (long)S->st_ctime));
    IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_FIELD_PTR(D, 11));

#ifdef HAVE_STAT_ST_CTIM_TV_NSEC
    IK_ASS(IK_FIELD(D, 12), ika_integer_from_ulong(pcb, (ik_ulong)S->st_ctim.tv_nsec));
    IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_FIELD_PTR(D, 12));
#elif (defined HAVE_STAT_ST_CTIMENSEC)
    IK_ASS(IK_FIELD(D, 12), ika_integer_from_ulong(pcb, (ik_ulong)S->st_ctimensec));
    IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_FIELD_PTR(D, 12));
#else
    IK_ASS(IK_FIELD(D, 12), IK_FALSE_OBJECT);
#endif

    IK_ASS(IK_FIELD(D, 13), ika_integer_from_ullong(pcb, (ik_ullong)S->st_blocks));
    IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_FIELD_PTR(D, 13));

    IK_ASS(IK_FIELD(D, 14), ika_integer_from_ullong(pcb, (ik_ullong)S->st_blksize));
    IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_FIELD_PTR(D, 13));
#else
    /* 64-bit platforms */
    IK_ASS(IK_FIELD(D, 0), ika_integer_from_ullong(pcb, (ik_ullong)S->st_mode));
    IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_FIELD_PTR(D, 0));
    IK_ASS(IK_FIELD(D, 1), ika_integer_from_ullong(pcb, (ik_ullong)S->st_ino));
    IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_FIELD_PTR(D, 1));
    IK_ASS(IK_FIELD(D, 2), ika_integer_from_llong(pcb, (long long)S->st_dev));
    IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_FIELD_PTR(D, 2));
    IK_ASS(IK_FIELD(D, 3), ika_integer_from_ullong(pcb, (ik_ullong)S->st_nlink));
    IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_FIELD_PTR(D, 3));

    IK_ASS(IK_FIELD(D, 4), ika_integer_from_ullong(pcb, (ik_ullong)S->st_uid));
    IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_FIELD_PTR(D, 4));
    IK_ASS(IK_FIELD(D, 5), ika_integer_from_ullong(pcb, (ik_ullong)S->st_gid));
    IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_FIELD_PTR(D, 5));
    IK_ASS(IK_FIELD(D, 6), ika_integer_from_ullong(pcb, (ik_ullong)S->st_size));
    IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_FIELD_PTR(D, 6));

    IK_ASS(IK_FIELD(D, 7), ika_integer_from_llong(pcb, (long long)S->st_atime));
    IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_FIELD_PTR(D, 7));
#ifdef HAVE_STAT_ST_ATIM_TV_NSEC
    IK_ASS(IK_FIELD(D, 8), ika_integer_from_ullong(pcb, (ik_ullong)S->st_atim.tv_nsec));
    IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_FIELD_PTR(D, 8));
#elif (defined HAVE_STAT_ST_ATIMENSEC)
    IK_ASS(IK_FIELD(D, 8), ika_integer_from_ullong(pcb, (ik_ullong)S->st_atimensec));
    IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_FIELD_PTR(D, 8));
#else
    IK_ASS(IK_FIELD(D, 8), IK_FALSE_OBJECT);
#endif

    IK_ASS(IK_FIELD(D, 9) , ika_integer_from_llong(pcb, (long long)S->st_mtime));
    IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_FIELD_PTR(D, 9));
#ifdef HAVE_STAT_ST_MTIM_TV_NSEC
    IK_ASS(IK_FIELD(D, 10), ika_integer_from_ullong(pcb, (ik_ullong)S->st_mtim.tv_nsec));
    IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_FIELD_PTR(D, 10));
#elif (defined HAVE_STAT_ST_MTIMENSEC)
    IK_ASS(IK_FIELD(D, 10), ika_integer_from_ullong(pcb, (ik_ullong)S->st_mtimensec));
    IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_FIELD_PTR(D, 10));
#else
    IK_ASS(IK_FIELD(D, 10), IK_FALSE_OBJECT);
#endif

    IK_ASS(IK_FIELD(D, 11), ika_integer_from_llong(pcb, (long long)S->st_ctime));
    IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_FIELD_PTR(D, 11));
#ifdef HAVE_STAT_ST_CTIM_TV_NSEC
    IK_ASS(IK_FIELD(D, 12), ika_integer_from_ullong(pcb, (ik_ullong)S->st_ctim.tv_nsec));
    IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_FIELD_PTR(D, 12));
#elif (defined HAVE_STAT_ST_CTIMENSEC)
    IK_ASS(IK_FIELD(D, 12), ika_integer_from_ullong(pcb, (ik_ullong)S->st_ctimensec));
    IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_FIELD_PTR(D, 12));
#else
    IK_ASS(IK_FIELD(D, 12), IK_FALSE_OBJECT);
#endif

    IK_ASS(IK_FIELD(D, 13), ika_integer_from_ullong(pcb, (ik_ullong)S->st_blocks));
    IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_FIELD_PTR(D, 13));
    IK_ASS(IK_FIELD(D, 14), ika_integer_from_ullong(pcb, (ik_ullong)S->st_blksize));
    IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_FIELD_PTR(D, 14));
#endif
  }
  pcb->root9 = NULL;
  return 0;
}
#endif
#ifdef HAVE_STAT
static ikptr_t
posix_stat (ikptr_t filename_bv, ikptr_t s_stat_struct, int follow_symlinks, ikpcb_t* pcb)
{
  char *	filename;
  struct stat	S;
  int		rv;
  filename = IK_BYTEVECTOR_DATA_CHARP(filename_bv);
  errno	   = 0;
  rv = (follow_symlinks)? stat(filename, &S) : lstat(filename, &S);
  return (0 == rv)? fill_stat_struct(&S, s_stat_struct, pcb) : ik_errno_to_code();
}
#endif
ikptr_t
ikrt_posix_stat (ikptr_t filename_bv, ikptr_t s_stat_struct, ikpcb_t* pcb)
{
#ifdef HAVE_STAT
  return posix_stat(filename_bv, s_stat_struct, 1, pcb);
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_lstat (ikptr_t filename_bv, ikptr_t s_stat_struct, ikpcb_t* pcb)
{
#ifdef HAVE_LSTAT
  return posix_stat(filename_bv, s_stat_struct, 0, pcb);
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_fstat (ikptr_t s_fd, ikptr_t s_stat_struct, ikpcb_t* pcb)
{
#ifdef HAVE_FSTAT
  struct stat	S;
  int		rv;
  errno = 0;
  rv	= fstat(IK_NUM_TO_FD(s_fd), &S);
  return (0 == rv)? fill_stat_struct(&S, s_stat_struct, pcb) : ik_errno_to_code();
#else
  feature_failure(__func__);
#endif
}

/* ------------------------------------------------------------------ */

ikptr_t
ikrt_posix_file_size(ikptr_t s_filename, ikpcb_t* pcb)
{
#ifdef HAVE_STAT
  char *	filename;
  struct stat	S;
  int		rv;
  filename = IK_BYTEVECTOR_DATA_CHARP(s_filename);
  errno	   = 0;
  rv	   = stat(filename, &S);
  if (0 == rv) {
#if 1
    return ika_integer_from_off_t(pcb, S.st_size);
#else
    if (sizeof(off_t) == sizeof(long))
      return ika_integer_from_ulong(pcb, S.st_size);
    else if (sizeof(off_t) == sizeof(long long))
      return ika_integer_from_ullong(pcb, S.st_size);
    else if (sizeof(off_t) == sizeof(int))
      return ika_integer_from_uint(pcb, S.st_size);
    else {
      ik_abort("unexpected off_t size %d", sizeof(off_t));
      return IK_VOID_OBJECT;
    }
#endif
  } else
    return ik_errno_to_code();
#else
  feature_failure(__func__);
#endif
}


/** --------------------------------------------------------------------
 ** File type predicates.
 ** ----------------------------------------------------------------- */

static ikptr_t
file_is_p (ikptr_t s_pathname, ikptr_t s_follow_symlinks, int flag)
{
#if (defined HAVE_STAT) && (defined HAVE_LSTAT)
  char *	pathname;
  struct stat	S;
  int		rv;
  pathname = IK_BYTEVECTOR_DATA_CHARP(s_pathname);
  errno	   = 0;
  rv	   = (IK_FALSE_OBJECT == s_follow_symlinks)? lstat(pathname, &S) : stat(pathname, &S);
  if (0 == rv)
    /* NOTE It is not enough to do "S.st_mode & flag", we really have to
       do "flag == (S.st_mode & flag)". */
    return (flag == (S.st_mode & flag))? IK_TRUE_OBJECT : IK_FALSE_OBJECT;
  else
    return ik_errno_to_code();
#else
  feature_failure(__func__);
#endif
}

#define FILE_IS_P(WHO,FLAG)					\
  ikptr_t WHO (ikptr_t s_pathname, ikptr_t s_follow_symlinks)		\
  { return file_is_p(s_pathname, s_follow_symlinks, FLAG); }

FILE_IS_P(ikrt_file_is_directory,	S_IFDIR)
FILE_IS_P(ikrt_file_is_char_device,	S_IFCHR)
FILE_IS_P(ikrt_file_is_block_device,	S_IFBLK)
FILE_IS_P(ikrt_file_is_regular_file,	S_IFREG)
FILE_IS_P(ikrt_file_is_symbolic_link,	S_IFLNK)
FILE_IS_P(ikrt_file_is_socket,		S_IFSOCK)
FILE_IS_P(ikrt_file_is_fifo,		S_IFIFO)

ikptr_t
ikrt_file_is_message_queue (ikptr_t s_pathname, ikptr_t s_follow_symlinks)
{
#if (defined HAVE_STAT) && (defined HAVE_LSTAT)
  char *	pathname;
  struct stat   S;
  int	   rv;
  pathname = IK_BYTEVECTOR_DATA_CHARP(s_pathname);
  errno    = 0;
  rv = (IK_FALSE_OBJECT == s_follow_symlinks)? lstat(pathname, &S) : stat(pathname, &S);
  if (0 == rv)
    return (S_TYPEISMQ(&S))? IK_TRUE_OBJECT : IK_FALSE_OBJECT;
  else
    return ik_errno_to_code();
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_file_is_semaphore (ikptr_t s_pathname, ikptr_t s_follow_symlinks)
{
#if (defined HAVE_STAT) && (defined HAVE_LSTAT)
  char *	pathname;
  struct stat   S;
  int	   rv;
  pathname = IK_BYTEVECTOR_DATA_CHARP(s_pathname);
  errno    = 0;
  rv = (IK_FALSE_OBJECT == s_follow_symlinks)? lstat(pathname, &S) : stat(pathname, &S);
  if (0 == rv)
    return (S_TYPEISSEM(&S))? IK_TRUE_OBJECT : IK_FALSE_OBJECT;
  else
    return ik_errno_to_code();
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_file_is_shared_memory (ikptr_t s_pathname, ikptr_t s_follow_symlinks)
{
#if (defined HAVE_STAT) && (defined HAVE_LSTAT)
  char *	pathname;
  struct stat   S;
  int	   rv;
  pathname = IK_BYTEVECTOR_DATA_CHARP(s_pathname);
  errno    = 0;
  rv = (IK_FALSE_OBJECT == s_follow_symlinks)? lstat(pathname, &S) : stat(pathname, &S);
  if (0 == rv)
    return (S_TYPEISSHM(&S))? IK_TRUE_OBJECT : IK_FALSE_OBJECT;
  else
    return ik_errno_to_code();
#else
  feature_failure(__func__);
#endif
}


/** --------------------------------------------------------------------
 ** Testing file access.
 ** ----------------------------------------------------------------- */

ikptr_t
ikrt_posix_access (ikptr_t s_pathname, ikptr_t how)
{
#ifdef HAVE_ACCESS
  char *	pathname = IK_BYTEVECTOR_DATA_CHARP(s_pathname);
  int		rv;
  errno = 0;
  rv	= access(pathname, IK_UNFIX(how));
  if (0 == rv)
    return IK_TRUE_OBJECT;
  else if ((errno == EACCES) ||
	   (errno == EROFS)  ||
	   (errno == ETXTBSY))
    return IK_FALSE_OBJECT;
  else
    return ik_errno_to_code();
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_file_exists (ikptr_t s_pathname)
{
#ifdef HAVE_STAT
  char *	pathname;
  struct stat	S;
  int		rv;
  pathname = IK_BYTEVECTOR_DATA_CHARP(s_pathname);
  errno	   = 0;
  rv	   = stat(pathname, &S);
  /* fprintf(stderr, "%s: %d, %d, %s, %s\n", __func__, rv, errno, pathname, getcwd(NULL, 0)); */
  if (0 == rv)
    return IK_TRUE_OBJECT;
  else if ((ENOENT == errno) || (ENOTDIR == errno))
    return IK_FALSE_OBJECT;
  else
    return ik_errno_to_code();
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_directory_exists (ikptr_t s_pathname)
{
#ifdef HAVE_STAT
  char *	pathname;
  struct stat	S;
  int		rv;
  pathname = IK_BYTEVECTOR_DATA_CHARP(s_pathname);
  errno	   = 0;
  rv	   = stat(pathname, &S);
  if (0 == rv)
    /* NOTE It is not enough to do "S.st_mode & flag", we really have to
       do "flag == (S.st_mode & flag)". */
    return (S_IFDIR == (S.st_mode & S_IFDIR))? IK_TRUE_OBJECT : IK_FALSE_OBJECT;
  else if ((ENOENT == errno) || (ENOTDIR == errno))
    return IK_FALSE_OBJECT;
  else
    return ik_errno_to_code();
#else
  feature_failure(__func__);
#endif
}


/** --------------------------------------------------------------------
 ** File times.
 ** ----------------------------------------------------------------- */

#ifdef HAVE_STRUCT_TIMESPEC
static ikptr_t
timespec_vector (struct timespec * T, ikptr_t s_vector, ikpcb_t* pcb)
{
  pcb->root9 = &s_vector;
  {
    IK_ASS(IK_ITEM(s_vector, 0), ika_integer_from_long(pcb, (long)(T->tv_sec )));
    IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_ITEM_PTR(s_vector, 0));
    IK_ASS(IK_ITEM(s_vector, 1), ika_integer_from_long(pcb, (long)(T->tv_nsec)));
    IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_ITEM_PTR(s_vector, 1));
  }
  pcb->root9 = NULL;
  return IK_FIX(0);
}
#endif
ikptr_t
ikrt_posix_file_ctime (ikptr_t s_pathname, ikptr_t s_vector, ikpcb_t* pcb)
{
#ifdef HAVE_STAT
  char*		pathname;
  struct stat	S;
  int		rv;
  pathname = IK_BYTEVECTOR_DATA_CHARP(s_pathname);
  errno	   = 0;
  rv	   = stat(pathname, &S);
  if (0 == rv) {
    struct timespec ts;
#ifdef HAVE_STAT_ST_CTIM_TV_NSEC
    ts.tv_sec  = S.st_ctime;
    ts.tv_nsec = S.st_ctim.tv_nsec;
#elif (defined HAVE_STAT_ST_CTIMENSEC)
    ts.tv_sec  = S.st_ctime;
    ts.tv_nsec = S.st_ctimensec;
#else
    ts.tv_sec  = s.st_ctime;
    ts.tv_nsec = 0;
#endif
    return timespec_vector(&ts, s_vector, pcb);
  } else
    return ik_errno_to_code();
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_file_mtime (ikptr_t s_pathname, ikptr_t s_vector, ikpcb_t* pcb)
{
#ifdef HAVE_STAT
  char*		pathname;
  struct stat	S;
  int		rv;
  pathname = IK_BYTEVECTOR_DATA_CHARP(s_pathname);
  errno	   = 0;
  rv	   = stat(pathname, &S);
  if (0 == rv) {
    struct timespec ts;
#ifdef HAVE_STAT_ST_MTIM_TV_NSEC
    ts.tv_sec  = S.st_mtime;
    ts.tv_nsec = S.st_mtim.tv_nsec;
#elif (defined HAVE_STAT_ST_MTIMENSEC)
    ts.tv_sec  = S.st_mtime;
    ts.tv_nsec = S.st_mtimensec;
#else
    ts.tv_sec  = s.st_mtime;
    ts.tv_nsec = 0;
#endif
    return timespec_vector(&ts, s_vector, pcb);
  } else
    return ik_errno_to_code();
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_file_atime (ikptr_t s_pathname, ikptr_t s_vector, ikpcb_t* pcb)
{
#ifdef HAVE_STAT
  char*		pathname;
  struct stat	S;
  int		rv;
  pathname = IK_BYTEVECTOR_DATA_CHARP(s_pathname);
  errno	   = 0;
  rv	   = stat(pathname, &S);
  if (0 == rv) {
    struct timespec ts;
#ifdef HAVE_STAT_ST_ATIM_TV_NSEC
    ts.tv_sec  = S.st_atime;
    ts.tv_nsec = S.st_atim.tv_nsec;
#elif (defined HAVE_STAT_ST_ATIMENSEC)
    ts.tv_sec  = S.st_atime;
    ts.tv_nsec = S.st_atimensec;
#else
    ts.tv_sec  = s.st_atime;
    ts.tv_nsec = 0;
#endif
    return timespec_vector(&ts, s_vector, pcb);
  } else
    return ik_errno_to_code();
#else
  feature_failure(__func__);
#endif
}


/** --------------------------------------------------------------------
 ** Setting onwers, permissions, times.
 ** ----------------------------------------------------------------- */

ikptr_t
ikrt_posix_chown (ikptr_t s_pathname, ikptr_t s_owner, ikptr_t s_group)
{
#ifdef HAVE_CHOWN
  char *  pathname;
  int	  rv;
  pathname = IK_BYTEVECTOR_DATA_CHARP(s_pathname);
  errno	   = 0;
  rv	   = chown(pathname, IK_NUM_TO_UID(s_owner), IK_NUM_TO_GID(s_group));
  return (0 == rv)? IK_FIX(0) : ik_errno_to_code();
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_fchown (ikptr_t s_fd, ikptr_t s_owner, ikptr_t s_group)
{
#ifdef HAVE_FCHOWN
  int	  rv;
  errno	   = 0;
  rv	   = fchown(IK_NUM_TO_FD(s_fd), IK_NUM_TO_UID(s_owner), IK_NUM_TO_GID(s_group));
  return (0 == rv)? IK_FIX(0) : ik_errno_to_code();
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_chmod (ikptr_t s_pathname, ikptr_t s_mode)
{
#ifdef HAVE_CHMOD
  char *	pathname;
  int		rv;
  mode_t	mode;
  pathname = IK_BYTEVECTOR_DATA_CHARP(s_pathname);
  mode	   = IK_NUM_TO_FILEMODE(s_mode);
  errno	   = 0;
  rv	   = chmod(pathname, mode);
  return (0 == rv)? IK_FIX(0) : ik_errno_to_code();
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_fchmod (ikptr_t s_fd, ikptr_t s_mode)
{
#ifdef HAVE_FCHMOD
  int		rv;
  mode_t	mode;
  mode	   = IK_NUM_TO_FILEMODE(s_mode);
  errno	   = 0;
  rv	   = fchmod(IK_NUM_TO_FD(s_fd), mode);
  return (0 == rv)? IK_FIX(0) : ik_errno_to_code();
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_umask (ikptr_t s_mask)
{
#ifdef HAVE_UMASK
  mode_t  mask = IK_NUM_TO_FILEMODE(s_mask);
  mode_t  rv   = umask(mask);
  return IK_FILEMODE_TO_NUM(rv);
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_getumask (void)
{
#ifdef HAVE_UMASK
  mode_t  mask = umask(0);
  umask(mask);
  return IK_FILEMODE_TO_NUM(mask);
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_utime (ikptr_t s_pathname, ikptr_t s_atime_sec, ikptr_t s_mtime_sec)
{
#ifdef HAVE_UTIME
  char *	  pathname;
  struct utimbuf  T;
  int		  rv;
  pathname  = IK_BYTEVECTOR_DATA_CHARP(s_pathname);
  T.actime  = (time_t)ik_integer_to_long(s_atime_sec);
  T.modtime = (time_t)ik_integer_to_long(s_mtime_sec);
  errno	    = 0;
  rv	    = utime(pathname, &T);
  return (0 == rv)? IK_FIX(0) : ik_errno_to_code();
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_utimes (ikptr_t s_pathname,
		   ikptr_t s_atime_sec, ikptr_t s_atime_usec,
		   ikptr_t s_mtime_sec, ikptr_t s_mtime_usec)
{
#ifdef HAVE_UTIMES
  char *	  pathname;
  struct timeval  T[2];
  int		  rv;
  pathname     = IK_BYTEVECTOR_DATA_CHARP(s_pathname);
  T[0].tv_sec  = (long)ik_integer_to_long(s_atime_sec);
  T[0].tv_usec = (long)ik_integer_to_long(s_atime_usec);
  T[1].tv_sec  = (long)ik_integer_to_long(s_mtime_sec);
  T[1].tv_usec = (long)ik_integer_to_long(s_mtime_usec);
  errno	       = 0;
  rv	       = utimes(pathname, T);
  return (0 == rv)? IK_FIX(0) : ik_errno_to_code();
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_lutimes (ikptr_t s_pathname,
		    ikptr_t s_atime_sec, ikptr_t s_atime_usec,
		    ikptr_t s_mtime_sec, ikptr_t s_mtime_usec)
{
#ifdef HAVE_LUTIMES
  char *	  pathname;
  struct timeval  T[2];
  int		  rv;
  pathname     = IK_BYTEVECTOR_DATA_CHARP(s_pathname);
  T[0].tv_sec  = (long)ik_integer_to_long(s_atime_sec);
  T[0].tv_usec = (long)ik_integer_to_long(s_atime_usec);
  T[1].tv_sec  = (long)ik_integer_to_long(s_mtime_sec);
  T[1].tv_usec = (long)ik_integer_to_long(s_mtime_usec);
  errno	       = 0;
  rv	       = lutimes(pathname, T);
  return (0 == rv)? IK_FIX(0) : ik_errno_to_code();
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_futimes (ikptr_t s_fd,
		    ikptr_t s_atime_sec, ikptr_t s_atime_usec,
		    ikptr_t s_mtime_sec, ikptr_t s_mtime_usec)
{
#ifdef HAVE_FUTIMES
  struct timeval  T[2];
  int		  rv;
  T[0].tv_sec  = (long)ik_integer_to_long(s_atime_sec);
  T[0].tv_usec = (long)ik_integer_to_long(s_atime_usec);
  T[1].tv_sec  = (long)ik_integer_to_long(s_mtime_sec);
  T[1].tv_usec = (long)ik_integer_to_long(s_mtime_usec);
  errno	       = 0;
  rv	       = futimes(IK_NUM_TO_FD(s_fd), T);
  return (0 == rv)? IK_FIX(0) : ik_errno_to_code();
#else
  feature_failure(__func__);
#endif
}


/** --------------------------------------------------------------------
 ** Hard and symbolic links.
 ** ----------------------------------------------------------------- */

ikptr_t
ikrt_posix_link (ikptr_t s_old_pathname, ikptr_t s_new_pathname)
{
#ifdef HAVE_LINK
  char *	old_pathname = IK_BYTEVECTOR_DATA_CHARP(s_old_pathname);
  char *	new_pathname = IK_BYTEVECTOR_DATA_CHARP(s_new_pathname);
  int		rv;
  errno = 0;
  rv	= link(old_pathname, new_pathname);
  return (0 == rv)? IK_FIX(0) : ik_errno_to_code();
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_symlink (ikptr_t s_true_pathname, ikptr_t s_link_pathname)
{
#ifdef HAVE_SYMLINK
  char *	true_pathname = IK_BYTEVECTOR_DATA_CHARP(s_true_pathname);
  char *	link_pathname = IK_BYTEVECTOR_DATA_CHARP(s_link_pathname);
  int		rv;
  errno = 0;
  rv	= symlink(true_pathname, link_pathname);
  return (0 == rv)? IK_FIX(0) : ik_errno_to_code();
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_readlink (ikptr_t s_link_pathname, ikpcb_t * pcb)
{
#ifdef HAVE_READLINK
  char *	link_pathname = IK_BYTEVECTOR_DATA_CHARP(s_link_pathname);
  size_t	max_len;
  int		rv;
  for (max_len=1024;; max_len *= 2) {
    char	true_pathname[max_len];
    errno = 0;
    rv	  = readlink(link_pathname, true_pathname, max_len);
    if (rv < 0)
      return ik_errno_to_code();
    else if (rv == max_len)
      continue;
    else
      return ika_bytevector_from_cstring_len(pcb, true_pathname, rv);
  }
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_realpath (ikptr_t s_link_pathname, ikpcb_t* pcb)
{
#ifdef HAVE_REALPATH
  char *	link_pathname;
  char *	true_pathname;
  link_pathname = IK_BYTEVECTOR_DATA_CHARP(s_link_pathname);
  errno		= 0;
  true_pathname = realpath(link_pathname, NULL);
  if (true_pathname) {
    ikptr_t	s_true_pathname = ika_bytevector_from_cstring(pcb, true_pathname);
    free(true_pathname);
    return s_true_pathname;
  } else
    return ik_errno_to_code();
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_unlink (ikptr_t s_pathname)
{
#ifdef HAVE_UNLINK
  char * pathname = IK_BYTEVECTOR_DATA_CHARP(s_pathname);
  int	 rv;
  errno = 0;
  rv	= unlink(pathname);
  return (0 == rv)? IK_FIX(0) : ik_errno_to_code();
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_remove (ikptr_t s_pathname)
{
#ifdef HAVE_REMOVE
  char * pathname = IK_BYTEVECTOR_DATA_CHARP(s_pathname);
  int	 rv;
  errno = 0;
  rv	= remove(pathname);
  return (0 == rv)? IK_FIX(0) : ik_errno_to_code();
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_rename (ikptr_t s_old_pathname, ikptr_t s_new_pathname)
{
#ifdef HAVE_RENAME
  char *	old_pathname = IK_BYTEVECTOR_DATA_CHARP(s_old_pathname);
  char *	new_pathname = IK_BYTEVECTOR_DATA_CHARP(s_new_pathname);
  int		rv;
  errno = 0;
  rv	= rename(old_pathname, new_pathname);
  return (0 == rv)? IK_FIX(0) : ik_errno_to_code();
#else
  feature_failure(__func__);
#endif
}


/** --------------------------------------------------------------------
 ** File system directories.
 ** ----------------------------------------------------------------- */

ikptr_t
ikrt_posix_mkdir (ikptr_t s_pathname, ikptr_t s_mode)
{
#ifdef HAVE_MKDIR
  char *	pathname;
  int		rv;
  pathname = IK_BYTEVECTOR_DATA_CHARP(s_pathname);
  errno	   = 0;
  rv	   = mkdir(pathname, IK_NUM_TO_FILEMODE(s_mode));
  return (0 == rv)? IK_FIX(0) : ik_errno_to_code();
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_rmdir (ikptr_t s_pathname)
{
#ifdef HAVE_RMDIR
  char *	pathname;
  int		rv;
  pathname = IK_BYTEVECTOR_DATA_CHARP(s_pathname);
  errno	   = 0;
  rv	   = rmdir(pathname);
  return (0 == rv)? IK_FIX(0) : ik_errno_to_code();
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_getcwd (ikpcb_t * pcb)
{
#ifdef HAVE_GETCWD
  size_t	max_len;
  char *	pathname;
  for (max_len=256;; max_len*=2) {
    char	buffer[max_len];
    errno    = 0;
    pathname = getcwd(buffer, max_len);
    if (NULL == pathname) {
      if (ERANGE == errno)
	continue;
      else
	return ik_errno_to_code();
    } else
      return ika_bytevector_from_cstring(pcb, pathname);
  }
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_chdir (ikptr_t s_pathname)
{
#ifdef HAVE_CHDIR
  char *	pathname;
  int		rv;
  pathname = IK_BYTEVECTOR_DATA_CHARP(s_pathname);
  errno	   = 0;
  rv	   = chdir(pathname);
  return (0 == rv)? IK_FIX(0) : ik_errno_to_code();
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_fchdir (ikptr_t s_fd)
{
#ifdef HAVE_FCHDIR
  int	rv;
  errno	   = 0;
  rv	   = fchdir(IK_NUM_TO_FD(s_fd));
  return (0 == rv)? IK_FIX(0) : ik_errno_to_code();
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_opendir (ikptr_t s_pathname, ikpcb_t * pcb)
{
#ifdef HAVE_OPENDIR
  char *	pathname;
  DIR *		stream;
  pathname = IK_BYTEVECTOR_DATA_CHARP(s_pathname);
  errno	   = 0;
  stream   = opendir(pathname);
  return (stream)? ika_pointer_alloc(pcb, (ikuword_t)stream) : ik_errno_to_code();
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_fdopendir (ikptr_t s_fd, ikpcb_t * pcb)
{
#ifdef HAVE_FDOPENDIR
  DIR *		stream;
  errno	   = 0;
  stream   = fdopendir(IK_NUM_TO_FD(s_fd));
  return (stream)? ika_pointer_alloc(pcb, (ikuword_t)stream) : ik_errno_to_code();
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_readdir (ikptr_t s_pointer, ikpcb_t * pcb)
{
#if ((defined HAVE_READDIR) && (defined HAVE_CLOSEDIR))
  DIR *		  stream = (DIR *) IK_POINTER_DATA_VOIDP(s_pointer);
  struct dirent * entry;
  errno = 0;
  entry = readdir(stream);
  if (NULL == entry) {
    closedir(stream);
    if (0 == errno)
      return IK_FALSE_OBJECT;
    else
      return ik_errno_to_code();
  } else
    /* The  only field	in  "struct dirent"  we	 can trust  to exist  is
       "d_name".   Notice that	the documentation  of glibc  describes a
       "d_namlen"  field  which	 does	not  exist  on	Linux,	see  the
       "readdir(3)" manual page. */
    return ika_bytevector_from_cstring(pcb, entry->d_name);
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_closedir (ikptr_t s_pointer, ikpcb_t * pcb)
{
#ifdef HAVE_CLOSEDIR
  DIR *	 stream = (DIR *) IK_POINTER_DATA_VOIDP(s_pointer);
  if (stream) {
    int	 rv;
    errno = 0;
    rv	= closedir(stream);
    if (0 == rv) {
      IK_POINTER_SET_NULL(s_pointer);
      return IK_FIX(0);
    } else
      return ik_errno_to_code();
  } else
    return IK_FIX(0);
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_rewinddir (ikptr_t s_pointer)
{
#ifdef HAVE_REWINDDIR
  DIR *	 stream = (DIR *) IK_POINTER_DATA_VOIDP(s_pointer);
  rewinddir(stream);
  return IK_VOID_OBJECT;
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_telldir (ikptr_t s_pointer, ikpcb_t * pcb)
{
#ifdef HAVE_TELLDIR
  DIR *	 stream = (DIR *) IK_POINTER_DATA_VOIDP(s_pointer);
  long	 pos;
  pos = telldir(stream);
  return ika_integer_from_long(pcb, pos);
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_seekdir (ikptr_t s_pointer, ikptr_t s_pos)
{
#ifdef HAVE_SEEKDIR
  DIR *	 stream = (DIR *) IK_POINTER_DATA_VOIDP(s_pointer);
  long	 pos	= ik_integer_to_long(s_pos);
  seekdir(stream, pos);
  return IK_VOID_OBJECT;
#else
  feature_failure(__func__);
#endif
}


/** --------------------------------------------------------------------
 ** File descriptors.
 ** ----------------------------------------------------------------- */

ikptr_t
ikrt_posix_open (ikptr_t s_pathname, ikptr_t s_flags, ikptr_t s_mode)
{
#ifdef HAVE_OPEN
  char *	pathname;
  int		rv;
  pathname = IK_BYTEVECTOR_DATA_CHARP(s_pathname);
  errno	   = 0;
  rv	   = open(pathname, IK_UNFIX(s_flags), IK_NUM_TO_FILEMODE(s_mode));
  return (0 <= rv)? IK_FIX(rv) : ik_errno_to_code();
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_close (ikptr_t s_fd)
{
#ifdef HAVE_CLOSE
  int	rv;
  errno	   = 0;
  rv	   = close(IK_NUM_TO_FD(s_fd));
  return (0 <= rv)? IK_FIX(rv) : ik_errno_to_code();
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_read (ikptr_t s_fd, ikptr_t s_buffer, ikptr_t s_size, ikpcb_t * pcb)
{
#ifdef HAVE_READ
  void *	buffer;
  size_t	size;
  ssize_t	rv;
  buffer = IK_GENERALISED_C_BUFFER(s_buffer);
  size   = ik_generalised_c_buffer_len(s_buffer, s_size);
  errno  = 0;
  rv     = read(IK_NUM_TO_FD(s_fd), buffer, size);
  return (0 <= rv)? ika_integer_from_ssize_t(pcb, rv) : ik_errno_to_code();
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_pread (ikptr_t s_fd, ikptr_t s_buffer, ikptr_t s_size, ikptr_t s_off, ikpcb_t * pcb)
{
#ifdef HAVE_PREAD
  void *	buffer;
  size_t	size;
  size_t	bv_size;
  off_t		off;
  ssize_t	rv;
  buffer   = IK_BYTEVECTOR_DATA_VOIDP(s_buffer);
  bv_size  = (size_t)IK_BYTEVECTOR_LENGTH(s_buffer);
  size	   = (IK_FALSE_OBJECT != s_size)? ik_integer_to_size_t(s_size) : bv_size;
  if (size <= bv_size) {
    off	   = ik_integer_to_off_t(s_off);
    errno  = 0;
    rv     = pread(IK_NUM_TO_FD(s_fd), buffer, size, off);
  } else {
    errno = EINVAL;
    rv    = -1;
  }
  return (0 <= rv)? ika_integer_from_ssize_t(pcb, rv) : ik_errno_to_code();
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_write (ikptr_t s_fd, ikptr_t s_buffer, ikptr_t s_size, ikpcb_t * pcb)
{
#ifdef HAVE_WRITE
  void *	buffer;
  size_t	size;
  size_t	bv_size;
  ssize_t	rv;
  buffer   = IK_BYTEVECTOR_DATA_VOIDP(s_buffer);
  bv_size  = (size_t)IK_BYTEVECTOR_LENGTH(s_buffer);
  size	   = (IK_FALSE_OBJECT != s_size)? ik_integer_to_size_t(s_size) : bv_size;
  if (size <= bv_size) {
    errno = 0;
    rv	  = write(IK_NUM_TO_FD(s_fd), buffer, size);
  } else {
    errno = EINVAL;
    rv    = -1;
  }
  return (0 <= rv)? ika_integer_from_ssize_t(pcb, rv) : ik_errno_to_code();
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_pwrite (ikptr_t s_fd, ikptr_t s_buffer, ikptr_t s_size, ikptr_t s_offset, ikpcb_t * pcb)
{
#ifdef HAVE_PWRITE
  void *	buffer;
  size_t	size;
  size_t	bv_size;
  off_t		off;
  ssize_t	rv;
  buffer  = IK_BYTEVECTOR_DATA_VOIDP(s_buffer);
  bv_size = (size_t)IK_BYTEVECTOR_LENGTH(s_buffer);
  size	  = (IK_FALSE_OBJECT != s_size)? ik_integer_to_size_t(s_size) : bv_size;
  if (size <= bv_size) {
    off   = ik_integer_to_off_t(s_offset);
    errno = 0;
    rv	  = pwrite(IK_NUM_TO_FD(s_fd), buffer, size, off);
  } else {
    errno = EINVAL;
    rv    = -1;
  }
  return (0 <= rv)? ika_integer_from_ssize_t(pcb, rv) : ik_errno_to_code();
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_lseek (ikptr_t s_fd, ikptr_t s_off, ikptr_t s_whence, ikpcb_t * pcb)
{
#ifdef HAVE_LSEEK
  off_t		off;
  off_t		rv;
  off	 = ik_integer_to_off_t(s_off);
  errno	 = 0;
  rv	 = lseek(IK_NUM_TO_FD(s_fd), off, IK_UNFIX(s_whence));
  return (0 <= rv)? ika_integer_from_off_t(pcb, rv) : ik_errno_to_code();
#else
  feature_failure(__func__);
#endif
}

/* ------------------------------------------------------------------ */

ikptr_t
ikrt_posix_readv (ikptr_t s_fd, ikptr_t s_buffers, ikpcb_t * pcb)
{
#ifdef HAVE_READV
  int		number_of_buffers = ik_list_length(s_buffers);
  struct iovec	bufs[number_of_buffers];
  ikptr_t		bv;
  int		i;
  ssize_t	rv;
  for (i=0; pair_tag == IK_TAGOF(s_buffers); s_buffers=IK_CDR(s_buffers), ++i) {
    bv	    = IK_REF(s_buffers, off_car);
    bufs[i].iov_base = IK_BYTEVECTOR_DATA_VOIDP(bv);
    bufs[i].iov_len  = IK_BYTEVECTOR_LENGTH(bv);
  }
  errno	   = 0;
  rv	   = readv(IK_NUM_TO_FD(s_fd), bufs, number_of_buffers);
  return (0 <= rv)? ika_integer_from_ssize_t(pcb, rv) : ik_errno_to_code();
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_writev (ikptr_t s_fd, ikptr_t s_buffers, ikpcb_t * pcb)
{
#ifdef HAVE_WRITEV
  int		number_of_buffers = ik_list_length(s_buffers);
  struct iovec	bufs[number_of_buffers];
  ikptr_t		bv;
  int		i;
  ssize_t	rv;
  for (i=0; pair_tag == IK_TAGOF(s_buffers); s_buffers=IK_CDR(s_buffers), ++i) {
    bv	    = IK_REF(s_buffers, off_car);
    bufs[i].iov_base = IK_BYTEVECTOR_DATA_VOIDP(bv);
    bufs[i].iov_len  = IK_BYTEVECTOR_LENGTH(bv);
  }
  errno	   = 0;
  rv	   = writev(IK_NUM_TO_FD(s_fd), bufs, number_of_buffers);
  return (0 <= rv)? ika_integer_from_ssize_t(pcb, rv) : ik_errno_to_code();
#else
  feature_failure(__func__);
#endif
}

/* ------------------------------------------------------------------ */

ikptr_t
ikrt_posix_select (ikptr_t nfds_fx,
		   ikptr_t read_fds_ell, ikptr_t write_fds_ell, ikptr_t except_fds_ell,
		   ikptr_t sec, ikptr_t usec,
		   ikpcb_t * pcb)
{
#ifdef HAVE_SELECT
  ikptr_t			L;	/* iterator for input lists */
  ikptr_t			R;	/* output list of read-ready fds */
  ikptr_t			W;	/* output list of write-ready fds */
  ikptr_t			E;	/* output list of except-ready fds */
  ikptr_t			vec;	/* the vector to be returned to the caller */
  fd_set		read_fds;
  fd_set		write_fds;
  fd_set		except_fds;
  struct timeval	timeout;
  int			fd, nfds=0;
  int			rv;
  /* Fill the fdset for read-ready descriptors. */
  FD_ZERO(&read_fds);
  for (L=read_fds_ell; pair_tag == IK_TAGOF(L); L = IK_REF(L, off_cdr)) {
    fd = IK_UNFIX(IK_REF(L, off_car));
    if (nfds < fd)
      nfds = fd;
    FD_SET(fd, &read_fds);
  }
  /* Fill the fdset for write-ready descriptors. */
  FD_ZERO(&write_fds);
  for (L=write_fds_ell; pair_tag == IK_TAGOF(L); L = IK_REF(L, off_cdr)) {
    fd = IK_UNFIX(IK_REF(L, off_car));
    if (nfds < fd)
      nfds = fd;
    FD_SET(fd, &write_fds);
  }
  /* Fill the fdset for except-ready descriptors. */
  FD_ZERO(&except_fds);
  for (L=except_fds_ell; pair_tag == IK_TAGOF(L); L = IK_REF(L, off_cdr)) {
    fd = IK_UNFIX(IK_REF(L, off_car));
    if (nfds < fd)
      nfds = fd;
    FD_SET(fd, &except_fds);
  }
  /* Perform the selection. */
  if (IK_FALSE_OBJECT == nfds_fx)
    ++nfds;
  else
    nfds = IK_UNFIX(nfds_fx);
  timeout.tv_sec  = IK_UNFIX(sec);
  timeout.tv_usec = IK_UNFIX(usec);
  errno = 0;
  rv	= select(nfds, &read_fds, &write_fds, &except_fds, &timeout);
  if (0 == rv) { /* timeout has expired */
    return IK_FIX(0);
  } else if (-1 == rv) { /* an error occurred */
    return ik_errno_to_code();
  } else { /* success, let's harvest the fds */
    /* Build the vector	 to be returned and prevent  it from being garbage
       collected while building other objects. */
    vec = ik_safe_alloc(pcb, IK_ALIGN(disp_vector_data+3*wordsize)) | vector_tag;
    IK_REF(vec, off_vector_length) = IK_FIX(3);
    IK_REF(vec, off_vector_data+0*wordsize) = IK_NULL_OBJECT;
    IK_REF(vec, off_vector_data+1*wordsize) = IK_NULL_OBJECT;
    IK_REF(vec, off_vector_data+2*wordsize) = IK_NULL_OBJECT;
    pcb->root0 = &vec;
    {
      /* Build a list of read-ready file descriptors. */
      for (L=read_fds_ell, R=IK_NULL_OBJECT; pair_tag == IK_TAGOF(L); L=IK_REF(L,off_cdr)) {
	ikptr_t fdx = IK_REF(L, off_car);
	if (FD_ISSET(IK_UNFIX(fdx), &read_fds)) {
	  ikptr_t P = ika_pair_alloc(pcb);
	  IK_CAR(P) = fdx;
	  IK_CDR(P) = R;
	  IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_CDR_PTR(P));
	  IK_ITEM(vec, 0) = P;
	  IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_ITEM_PTR(vec, 0));
	  R = P;
	}
      }
      /* Build a list of write-ready file descriptors. */
      for (L=write_fds_ell, W=IK_NULL_OBJECT; pair_tag == IK_TAGOF(L); L = IK_REF(L, off_cdr)) {
	ikptr_t fdx = IK_REF(L, off_car);
	if (FD_ISSET(IK_UNFIX(fdx), &write_fds)) {
	  ikptr_t P = ika_pair_alloc(pcb);
	  IK_CAR(P) = fdx;
	  IK_CDR(P) = W;
	  IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_CDR_PTR(P));
	  IK_ITEM(vec, 1) = W = P;
	  IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_ITEM_PTR(vec, 1));
	}
      }
      /* Build a list of except-ready file descriptors. */
      for (L=except_fds_ell, E=IK_NULL_OBJECT; pair_tag == IK_TAGOF(L); L = IK_REF(L, off_cdr)) {
	ikptr_t fdx = IK_REF(L, off_car);
	if (FD_ISSET(IK_UNFIX(fdx), &except_fds)) {
	  ikptr_t P = ika_pair_alloc(pcb);
	  IK_CAR(P) = fdx;
	  IK_CDR(P) = E;
	  IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_CDR_PTR(P));
	  IK_ITEM(vec, 2) = E = P;
	  IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_ITEM_PTR(vec, 2));
	}
      }
    }
    pcb->root0 = NULL;
    return vec;
  }
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_select_fd (ikptr_t s_fd, ikptr_t sec, ikptr_t usec, ikpcb_t * pcb)
{
#ifdef HAVE_SELECT
  fd_set		read_fds;
  fd_set		write_fds;
  fd_set		except_fds;
  struct timeval	timeout;
  int			fd;
  int			rv;
  FD_ZERO(&read_fds);
  FD_ZERO(&write_fds);
  FD_ZERO(&except_fds);
  fd = IK_NUM_TO_FD(s_fd);
  FD_SET(fd, &read_fds);
  FD_SET(fd, &write_fds);
  FD_SET(fd, &except_fds);
  timeout.tv_sec  = IK_UNFIX(sec);
  timeout.tv_usec = IK_UNFIX(usec);
  errno = 0;
  rv	= select(1+fd, &read_fds, &write_fds, &except_fds, &timeout);
  if (0 == rv) { /* timeout has expired */
    return IK_FIX(0);
  } else if (-1 == rv) { /* an error occurred */
    return ik_errno_to_code();
  } else { /* success, let's harvest the events */
    int		result = 0;
    if (FD_ISSET(fd, &read_fds))
      result |= 1;
    if (FD_ISSET(fd, &write_fds))
      result |= 2;
    if (FD_ISSET(fd, &except_fds))
      result |= 4;
    return IK_FIX(result);
  }
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_select_is_readable (ikptr_t s_fd, ikptr_t s_sec, ikptr_t s_usec, ikpcb_t * pcb)
/* Interface to the C function  "select()" for a single file descriptor.
   Wait for  a readable event with  timeout. The file  descriptor is the
   fixnum S_FD.   S_SEC and S_USEC must be  fixnums representing timeout
   seconds and microseconds.

   Return false  if the timeout  expires before any event  arrives; else
   return true  if the  file descriptor becomes  readable.  If  an error
   occurs: return an encoded "errno" value.  */
{
#ifdef HAVE_SELECT
  fd_set		read_fds;
  fd_set		write_fds;
  fd_set		except_fds;
  struct timeval	timeout;
  int			fd;
  int			rv;
  FD_ZERO(&read_fds);
  FD_ZERO(&write_fds);
  FD_ZERO(&except_fds);
  fd = IK_NUM_TO_FD(s_fd);
  FD_SET(fd, &read_fds);
  timeout.tv_sec  = IK_UNFIX(s_sec);
  timeout.tv_usec = IK_UNFIX(s_usec);
  errno = 0;
  rv	= select(1+fd, &read_fds, &write_fds, &except_fds, &timeout);
  if (0 == rv) /* timeout has expired */
    return IK_FALSE_OBJECT;
  else if (-1 == rv) /* an error occurred */
    return ik_errno_to_code();
  else /* success, let's harvest the events */
    return (FD_ISSET(fd, &read_fds))? IK_TRUE_OBJECT : IK_FALSE_OBJECT;
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_select_is_writable (ikptr_t s_fd, ikptr_t s_sec, ikptr_t s_usec, ikpcb_t * pcb)
/* Interface to the C function  "select()" for a single file descriptor.
   Wait for  a writable event with  timeout. The file  descriptor is the
   fixnum S_FD.   S_SEC and S_USEC must be  fixnums representing timeout
   seconds and microseconds.

   Return false  if the timeout  expires before any event  arrives; else
   return true  if the  file descriptor becomes  writable.  If  an error
   occurs: return an encoded "errno" value.  */
{
#ifdef HAVE_SELECT
  fd_set		read_fds;
  fd_set		write_fds;
  fd_set		except_fds;
  struct timeval	timeout;
  int			fd;
  int			rv;
  FD_ZERO(&read_fds);
  FD_ZERO(&write_fds);
  FD_ZERO(&except_fds);
  fd = IK_NUM_TO_FD(s_fd);
  FD_SET(fd, &write_fds);
  timeout.tv_sec  = IK_UNFIX(s_sec);
  timeout.tv_usec = IK_UNFIX(s_usec);
  errno = 0;
  rv	= select(1+fd, &read_fds, &write_fds, &except_fds, &timeout);
  if (0 == rv) /* timeout has expired */
    return IK_FALSE_OBJECT;
  else if (-1 == rv) /* an error occurred */
    return ik_errno_to_code();
  else /* success, let's harvest the events */
    return (FD_ISSET(fd, &write_fds))? IK_TRUE_OBJECT : IK_FALSE_OBJECT;
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_select_is_exceptional (ikptr_t s_fd, ikptr_t s_sec, ikptr_t s_usec, ikpcb_t * pcb)
/* Interface to the C function  "select()" for a single file descriptor.
   Wait for  an exceptional event  with timeout. The file  descriptor is
   the  fixnum S_FD.   S_SEC  and S_USEC  must  be fixnums  representing
   timeout seconds and microseconds.

   Return false  if the timeout  expires before any event  arrives; else
   return  true   if  the   file  descriptor  receives   an  exceptional
   notification.   If  an  error   occurs:  return  an  encoded  "errno"
   value.  */
{
#ifdef HAVE_SELECT
  fd_set		read_fds;
  fd_set		write_fds;
  fd_set		except_fds;
  struct timeval	timeout;
  int			fd;
  int			rv;
  FD_ZERO(&read_fds);
  FD_ZERO(&write_fds);
  FD_ZERO(&except_fds);
  fd = IK_NUM_TO_FD(s_fd);
  FD_SET(fd, &except_fds);
  timeout.tv_sec  = IK_UNFIX(s_sec);
  timeout.tv_usec = IK_UNFIX(s_usec);
  errno = 0;
  rv	= select(1+fd, &read_fds, &write_fds, &except_fds, &timeout);
  if (0 == rv) /* timeout has expired */
    return IK_FALSE_OBJECT;
  else if (-1 == rv) /* an error occurred */
    return ik_errno_to_code();
  else /* success, let's harvest the events */
    return (FD_ISSET(fd, &except_fds))? IK_TRUE_OBJECT : IK_FALSE_OBJECT;
#else
  feature_failure(__func__);
#endif
}

/* ------------------------------------------------------------------ */

ikptr_t
ikrt_posix_poll (ikptr_t s_fds, ikptr_t s_timeout)
{
#ifdef HAVE_POLL
  long		nfds    = (long)IK_VECTOR_LENGTH(s_fds);
  int		timeout = ik_integer_to_int(s_timeout);
  struct pollfd	fds[nfds];
  int		rv, i;
  for (i=0; i<nfds; ++i) {
    ikptr_t	S = IK_ITEM(s_fds, i);
    fds[i].fd      = IK_NUM_TO_FD(IK_ITEM(S, 0));
    fds[i].events  = IK_UNFIX(IK_ITEM(S, 1));
    fds[i].revents = 0;
  }
  errno = 0;
  rv    = poll(fds, nfds, timeout);
  if (-1 == rv)
    return ik_errno_to_code();
  else {
    for (i=0; i<nfds; ++i) {
      ikptr_t	S = IK_ITEM(s_fds, i);
      IK_ITEM(S, 2) = IK_FIX(fds[i].revents);
    }
    return IK_FIX(rv);
  }
#else
  feature_failure(__func__);
#endif
}

/* ------------------------------------------------------------------ */

ikptr_t
ikrt_posix_fcntl (ikptr_t fd, ikptr_t command, ikptr_t arg)
{
#ifdef HAVE_FCNTL
  int		rv = -1;
  errno = 0;
  if (IK_IS_FIXNUM(arg)) {
    long	val = (long)IK_UNFIX(arg);
    rv = fcntl(IK_UNFIX(fd), IK_UNFIX(command), val);
  } else if (IK_FALSE_OBJECT == arg) {
    rv = fcntl(IK_UNFIX(fd), IK_UNFIX(command));
  } else if (IK_IS_BYTEVECTOR(arg)) {
    void *	val = IK_BYTEVECTOR_DATA_VOIDP(arg);
    rv = fcntl(IK_UNFIX(fd), IK_UNFIX(command), val);
  } else if (ikrt_is_pointer(arg)) {
    void *	val = IK_POINTER_DATA_VOIDP(arg);
    rv = fcntl(IK_UNFIX(fd), IK_UNFIX(command), val);
  } else
    ik_abort("invalid last argument to fcntl()");
  return (-1 != rv)? IK_FIX(rv) : ik_errno_to_code();
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_ioctl (ikptr_t fd, ikptr_t command, ikptr_t arg)
{
#ifdef HAVE_IOCTL
  int		rv = -1;
  errno = 0;
  if (IK_IS_FIXNUM(arg)) {
    long	val = (long)IK_UNFIX(arg);
    rv = ioctl(IK_UNFIX(fd), IK_UNFIX(command), val);
  } else if (IK_FALSE_OBJECT == arg) {
    rv = ioctl(IK_UNFIX(fd), IK_UNFIX(command));
  } else if (IK_IS_BYTEVECTOR(arg)) {
    void *	val = IK_BYTEVECTOR_DATA_VOIDP(arg);
    rv = ioctl(IK_UNFIX(fd), IK_UNFIX(command), val);
  } else if (ikrt_is_pointer(arg)) {
    void *	val = IK_POINTER_DATA_VOIDP(arg);
    rv = ioctl(IK_UNFIX(fd), IK_UNFIX(command), val);
  } else
    ik_abort("invalid last argument to ioctl()");
  return (-1 != rv)? IK_FIX(rv) : ik_errno_to_code();
#else
  feature_failure(__func__);
#endif
}

/* ------------------------------------------------------------------ */

ikptr_t
ikptr_posix_fd_set_non_blocking_mode (ikptr_t s_fd, ikpcb_t * pcb)
/* Notice  that  O_NONBLOCK  needs  the F_SETFL  and  F_GETFL  commands.
   FD_CLOEXEC needs the F_SETFD and F_GETFD commands. */
{
#ifdef HAVE_FCNTL
  int		fd = IK_NUM_TO_FD(s_fd);
  int		rv;
  errno = 0;
  rv = fcntl(fd, F_GETFL, 0);
  if (-1 == rv) return ik_errno_to_code();
  errno = 0;
  rv = fcntl(fd, F_SETFL, rv | O_NONBLOCK);
  return (-1 != rv)? IK_FIX(rv) : ik_errno_to_code();
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikptr_posix_fd_unset_non_blocking_mode (ikptr_t s_fd, ikpcb_t * pcb)
/* Notice  that  O_NONBLOCK  needs  the F_SETFL  and  F_GETFL  commands.
   FD_CLOEXEC needs the F_SETFD and F_GETFD commands. */
{
#ifdef HAVE_FCNTL
  int		fd = IK_NUM_TO_FD(s_fd);
  int		rv;
  errno = 0;
  rv = fcntl(fd, F_GETFL, 0);
  if (-1 == rv) return ik_errno_to_code();
  errno = 0;
  rv = fcntl(fd, F_SETFL, rv & (~O_NONBLOCK));
  return (-1 != rv)? IK_FIX(rv) : ik_errno_to_code();
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikptr_posix_fd_ref_non_blocking_mode (ikptr_t s_fd, ikpcb_t * pcb)
/* Notice  that  O_NONBLOCK  needs  the F_SETFL  and  F_GETFL  commands.
   FD_CLOEXEC needs the F_SETFD and F_GETFD commands. */
{
#ifdef HAVE_FCNTL
  int		fd = IK_NUM_TO_FD(s_fd);
  int		rv;
  errno = 0;
  rv = fcntl(fd, F_GETFL, 0);
  return (-1 != rv)? IK_BOOLEAN_FROM_INT(rv & O_NONBLOCK) : ik_errno_to_code();
#else
  feature_failure(__func__);
#endif
}

/* ------------------------------------------------------------------ */

ikptr_t
ikptr_posix_fd_set_close_on_exec_mode (ikptr_t s_fd, ikpcb_t * pcb)
/* Notice  that  FD_CLOEXEC  needs  the F_SETFD  and  F_GETFD  commands.
   O_NONBLOCK needs the F_SETFL and F_GETFL commands. */
{
#ifdef HAVE_FCNTL
  int		fd = IK_NUM_TO_FD(s_fd);
  int		rv;
  errno = 0;
  rv = fcntl(fd, F_GETFD, 0);
  if (-1 == rv) return ik_errno_to_code();
  errno = 0;
  rv = fcntl(fd, F_SETFD, rv | FD_CLOEXEC);
  return (-1 != rv)? IK_FIX(rv) : ik_errno_to_code();
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikptr_posix_fd_unset_close_on_exec_mode (ikptr_t s_fd, ikpcb_t * pcb)
/* Notice  that  FD_CLOEXEC  needs  the F_SETFD  and  F_GETFD  commands.
   O_NONBLOCK needs the F_SETFL and F_GETFL commands. */
{
#ifdef HAVE_FCNTL
  int		fd = IK_NUM_TO_FD(s_fd);
  int		rv;
  errno = 0;
  rv = fcntl(fd, F_GETFD, 0);
  if (-1 == rv) return ik_errno_to_code();
  errno = 0;
  rv = fcntl(fd, F_SETFD, rv & (~FD_CLOEXEC));
  return (-1 != rv)? IK_FIX(rv) : ik_errno_to_code();
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikptr_posix_fd_ref_close_on_exec_mode (ikptr_t s_fd, ikpcb_t * pcb)
/* Notice  that  FD_CLOEXEC  needs  the F_SETFD  and  F_GETFD  commands.
   O_NONBLOCK needs the F_SETFL and F_GETFL commands. */
{
#ifdef HAVE_FCNTL
  int		fd = IK_NUM_TO_FD(s_fd);
  int		rv;
  errno = 0;
  rv = fcntl(fd, F_GETFD, 0);
  return (-1 != rv)? IK_BOOLEAN_FROM_INT(rv & FD_CLOEXEC) : ik_errno_to_code();
#else
  feature_failure(__func__);
#endif
}

/* ------------------------------------------------------------------ */

ikptr_t
ikrt_posix_dup (ikptr_t fd)
{
#ifdef HAVE_DUP
  int	rv;
  errno = 0;
  rv	= dup(IK_UNFIX(fd));
  return (-1 != rv)? IK_FIX(rv) : ik_errno_to_code();
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_dup2 (ikptr_t old, ikptr_t new)
{
#ifdef HAVE_DUP2
  int	rv;
  errno = 0;
  rv	= dup2(IK_UNFIX(old), IK_UNFIX(new));
  return (-1 != rv)? IK_FIX(0) : ik_errno_to_code();
#else
  feature_failure(__func__);
#endif
}

/* ------------------------------------------------------------------ */

ikptr_t
ikrt_posix_pipe (ikpcb_t * pcb)
{
#ifdef HAVE_PIPE
  int	rv;
  int	fds[2];
  errno = 0;
  rv	= pipe(fds);
  if (-1 == rv)
    return ik_errno_to_code();
  else {
    ikptr_t  pair = ika_pair_alloc(pcb);
    /* No  need to  update the  dirty vector  about "pair",  because the
       values are fixnums. */
    IK_CAR(pair) = IK_FIX(fds[0]);
    IK_CDR(pair) = IK_FIX(fds[1]);
    return pair;
  }
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_mkfifo (ikptr_t s_pathname, ikptr_t mode)
{
#ifdef HAVE_MKFIFO
  char *	pathname;
  int		rv;
  pathname = IK_BYTEVECTOR_DATA_CHARP(s_pathname);
  errno	   = 0;
  rv	   = mkfifo(pathname, IK_UNFIX(mode));
  return (0 <= rv)? IK_FIX(rv) : ik_errno_to_code();
#else
  feature_failure(__func__);
#endif
}

/* ------------------------------------------------------------------ */

ikptr_t
ikrt_posix_truncate (ikptr_t s_name, ikptr_t s_length)
{
#ifdef HAVE_TRUNCATE
  const char *	name = IK_BYTEVECTOR_DATA_CHARP(s_name);
  off_t		len  = ik_integer_to_off_t(s_length);
  int		rv;
  errno = 0;
  rv	= truncate(name, len);
  return (0 == rv)? IK_FIX(0) : ik_errno_to_code();
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_ftruncate (ikptr_t s_fd, ikptr_t s_length)
{
#ifdef HAVE_FTRUNCATE
  off_t	len  = ik_integer_to_off_t(s_length);
  int	rv;
  errno = 0;
  rv	= ftruncate(IK_NUM_TO_FD(s_fd), len);
  return (0 == rv)? IK_FIX(0) : ik_errno_to_code();
#else
  feature_failure(__func__);
#endif
}

/* ------------------------------------------------------------------ */

ikptr_t
ikrt_posix_lockf (ikptr_t s_fd, ikptr_t s_cmd, ikptr_t s_len)
{
#ifdef HAVE_LOCKF
  int	cmd  = ik_integer_to_int(s_cmd);
  off_t	len  = ik_integer_to_off_t(s_len);
  int	rv;
  errno = 0;
  rv	= lockf(IK_NUM_TO_FD(s_fd), cmd, len);
  return (0 == rv)? IK_FIX(0) : ik_errno_to_code();
#else
  feature_failure(__func__);
#endif
}


/** --------------------------------------------------------------------
 ** File descriptor sets.
 ** ----------------------------------------------------------------- */

ikptr_t
ikrt_posix_sizeof_fd_set (ikptr_t s_count, ikpcb_t * pcb)
{
  /* Yes, we do not check for overflow. */
  size_t	len = sizeof(fd_set) * IK_UNFIX(s_count);
  return ika_integer_from_size_t(pcb, len);
}
ikptr_t
ikrt_posix_make_fd_set_bytevector (ikptr_t s_count, ikpcb_t * pcb)
{
  iksword_t	count	= IK_UNFIX(s_count);
  /* Yes, we do not check for overflow. */
  iksword_t	len	= sizeof(fd_set) * count;
  ikptr_t		bv	= ika_bytevector_alloc(pcb, len);
  fd_set *	set	= (fd_set *)IK_BYTEVECTOR_DATA_VOIDP(bv);
  for (long i=0; i<count; ++i)
    FD_ZERO(&(set[i]));
  return bv;
}
ikptr_t
ikrt_posix_make_fd_set_pointer (ikptr_t s_count, ikpcb_t * pcb)
{
  iksword_t	count	= IK_UNFIX(s_count);
  /* Yes, we do not check for overflow. */
  size_t	len = sizeof(fd_set) * count;
  fd_set *	set = malloc(len);
  if (set) {
    for (long i=0; i<count; ++i)
      FD_ZERO(&(set[i]));
    return ika_pointer_alloc(pcb, (ikuword_t)set);
  } else
    return IK_FALSE;
}
ikptr_t
ikrt_posix_make_fd_set_memory_block (ikptr_t s_mblock, ikptr_t s_count, ikpcb_t * pcb)
{
  iksword_t	count	= IK_UNFIX(s_count);
  /* Yes, we do not check for overflow. */
  size_t	len = sizeof(fd_set) * count;
  fd_set *	set = malloc(len);
  if (set) {
    for (long i=0; i<count; ++i)
      FD_ZERO(&(set[i]));
    pcb->root0 = &s_mblock;
    {
      IK_POINTER_SET(IK_MBLOCK_POINTER(s_mblock), (ikptr_t)set);
      IK_ASS(IK_MBLOCK_SIZE(s_mblock), ika_integer_from_size_t(pcb, len));
      IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_FIELD_PTR(s_mblock, 1));
    }
    pcb->root0 = NULL;
    return IK_TRUE;
  } else
    return IK_FALSE;
}

/* ------------------------------------------------------------------ */

ikptr_t
ikrt_posix_fd_zero (ikptr_t s_fdset, ikptr_t s_idx, ikpcb_t * pcb)
{
  fd_set *	set = IK_VOIDP_FROM_BYTEVECTOR_OR_POINTER_OR_MBLOCK_OR_FALSE(s_fdset);
  if (set) {
    int		idx = IK_UNFIX(s_idx);
    FD_ZERO(&(set[idx]));
  }
  return IK_VOID;
}
ikptr_t
ikrt_posix_fd_set (ikptr_t s_fd, ikptr_t s_fdset, ikptr_t s_idx, ikpcb_t * pcb)
{
  fd_set *	set = IK_VOIDP_FROM_BYTEVECTOR_OR_POINTER_OR_MBLOCK(s_fdset);
  int		idx = IK_UNFIX(s_idx);
  int		fd  = IK_NUM_TO_FD(s_fd);
  FD_SET(fd, &(set[idx]));
  return IK_VOID;
}
ikptr_t
ikrt_posix_fd_clr (ikptr_t s_fd, ikptr_t s_fdset, ikptr_t s_idx, ikpcb_t * pcb)
{
  fd_set *	set = IK_VOIDP_FROM_BYTEVECTOR_OR_POINTER_OR_MBLOCK(s_fdset);
  int		idx = IK_UNFIX(s_idx);
  int		fd  = IK_NUM_TO_FD(s_fd);
  FD_CLR(fd, &(set[idx]));
  return IK_VOID;
}
ikptr_t
ikrt_posix_fd_isset (ikptr_t s_fd, ikptr_t s_fdset, ikptr_t s_idx, ikpcb_t * pcb)
{
  fd_set *	set = IK_VOIDP_FROM_BYTEVECTOR_OR_POINTER_OR_MBLOCK(s_fdset);
  int		idx = IK_UNFIX(s_idx);
  int		fd  = IK_NUM_TO_FD(s_fd);
  int		rv;
  rv = FD_ISSET(fd, &(set[idx]));
  return IK_BOOLEAN_FROM_INT(rv);
}

/* ------------------------------------------------------------------ */

ikptr_t
ikrt_posix_select_from_sets (ikptr_t s_nfds,
			     ikptr_t s_read_fds, ikptr_t s_write_fds, ikptr_t s_except_fds,
			     ikptr_t s_sec, ikptr_t s_usec,
			     ikpcb_t * pcb)
{
#ifdef HAVE_SELECT
  fd_set *	read_fds   = \
    IK_VOIDP_FROM_BYTEVECTOR_OR_POINTER_OR_MBLOCK_OR_FALSE(s_read_fds);
  fd_set *	write_fds  = \
    IK_VOIDP_FROM_BYTEVECTOR_OR_POINTER_OR_MBLOCK_OR_FALSE(s_write_fds);
  fd_set *	except_fds = \
    IK_VOIDP_FROM_BYTEVECTOR_OR_POINTER_OR_MBLOCK_OR_FALSE(s_except_fds);
  fd_set	empty_read;
  fd_set	empty_write;
  fd_set	empty_except;
  struct timeval timeout;
  int		nfds=0;
  int		rv;
  nfds = (IK_FALSE == s_nfds)? FD_SETSIZE : IK_UNFIX(s_nfds);
  if (NULL == read_fds) {
    read_fds = &empty_read;
    FD_ZERO(read_fds);
  }
  if (NULL == write_fds) {
    write_fds = &empty_write;
    FD_ZERO(write_fds);
  }
  if (NULL == except_fds) {
    except_fds = &empty_except;
    FD_ZERO(except_fds);
  }
  timeout.tv_sec  = IK_UNFIX(s_sec);
  timeout.tv_usec = IK_UNFIX(s_usec);
  errno = 0;
  rv	= select(nfds, read_fds, write_fds, except_fds, &timeout);
  if (0 == rv) { /* timeout has expired */
    return IK_FIX(0);
  } else if (-1 == rv) { /* an error occurred */
    return ik_errno_to_code();
  } else /* success */
    return IK_FALSE;
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_select_from_sets_array (ikptr_t s_nfds, ikptr_t s_fd_sets,
				   ikptr_t s_sec, ikptr_t s_usec, ikpcb_t * pcb)
{
#ifdef HAVE_SELECT
  fd_set *	fd_sets    = IK_VOIDP_FROM_BYTEVECTOR_OR_POINTER_OR_MBLOCK(s_fd_sets);
  fd_set *	read_fds   = &(fd_sets[0]);
  fd_set *	write_fds  = &(fd_sets[1]);
  fd_set *	except_fds = &(fd_sets[2]);
  struct timeval timeout;
  int		nfds=0;
  int		rv;
  nfds = (IK_FALSE == s_nfds)? FD_SETSIZE : IK_UNFIX(s_nfds);
  timeout.tv_sec  = IK_UNFIX(s_sec);
  timeout.tv_usec = IK_UNFIX(s_usec);
  errno = 0;
  rv	= select(nfds, read_fds, write_fds, except_fds, &timeout);
  if (0 == rv) { /* timeout has expired */
    return IK_FIX(0);
  } else if (-1 == rv) { /* an error occurred */
    return ik_errno_to_code();
  } else /* success */
    return IK_FALSE;
#else
  feature_failure(__func__);
#endif
}


/** --------------------------------------------------------------------
 ** Memory-mapped input/output.
 ** ----------------------------------------------------------------- */

ikptr_t
ikrt_posix_mmap (ikptr_t s_address, ikptr_t s_length, ikptr_t s_protect,
		 ikptr_t s_flags, ikptr_t s_fd, ikptr_t s_offset, ikpcb_t * pcb)
{
#ifdef HAVE_MMAP
  void *	address = (IK_FALSE_OBJECT == s_address)? NULL : IK_POINTER_DATA_VOIDP(s_address);
  size_t	length  = ik_integer_to_size_t(s_length);
  off_t		offset  = ik_integer_to_off_t(s_offset);
  void *	rv;
  errno = 0;
  rv    = mmap(address, length,
	       IK_UNFIX(s_protect), IK_UNFIX(s_flags),
	       IK_NUM_TO_FD(s_fd), offset);
  /* if (((void *)-1) != rv) */
  if (MAP_FAILED != rv)
    return ika_pointer_alloc(pcb, (ikuword_t)rv);
  else
    return ik_errno_to_code();
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_munmap (ikptr_t s_address, ikptr_t s_length)
{
#ifdef HAVE_MUNMAP
  void *	address = IK_POINTER_DATA_VOIDP(s_address);
  size_t	length  = ik_integer_to_size_t(s_length);
  int		rv;
  errno = 0;
  rv    = munmap(address, length);
  return (0 == rv)? IK_FIX(0) : ik_errno_to_code();
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_msync (ikptr_t s_address, ikptr_t s_length, ikptr_t s_flags)
{
#ifdef HAVE_MSYNC
  void *	address = IK_POINTER_DATA_VOIDP(s_address);
  size_t	length  = ik_integer_to_size_t(s_length);
  int		rv;
  errno = 0;
  rv    = msync(address, length, IK_UNFIX(s_flags));
  return (0 == rv)? IK_FIX(0) : ik_errno_to_code();
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_mremap (ikptr_t s_address, ikptr_t s_length, ikptr_t s_new_length, ikptr_t s_flags, ikpcb_t * pcb)
{
#ifdef HAVE_MREMAP
  void *	address     = IK_POINTER_DATA_VOIDP(s_address);
  size_t	length      = ik_integer_to_size_t(s_length);
  size_t	new_length  = ik_integer_to_size_t(s_new_length);
  void *	rv;
  errno = 0;
  rv    = mremap(address, length, new_length, IK_UNFIX(s_flags));
  if (((void *)-1) != rv)
    return ika_pointer_alloc(pcb, (ikuword_t)rv);
  else
    return ik_errno_to_code();
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_madvise (ikptr_t s_address, ikptr_t s_length, ikptr_t s_advice)
{
#ifdef HAVE_MADVISE
  void *	address = IK_POINTER_DATA_VOIDP(s_address);
  size_t	length  = ik_integer_to_size_t(s_length);
  int		rv;
  errno = 0;
  rv    = madvise(address, length, IK_UNFIX(s_advice));
  return (0 == rv)? IK_FIX(0) : ik_errno_to_code();
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_mlock (ikptr_t s_address, ikptr_t s_length)
{
#ifdef HAVE_MLOCK
  void *	address = IK_POINTER_DATA_VOIDP(s_address);
  size_t	length  = ik_integer_to_size_t(s_length);
  int		rv;
  errno = 0;
  rv    = mlock(address, length);
  return (0 == rv)? IK_FIX(0) : ik_errno_to_code();
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_munlock (ikptr_t s_address, ikptr_t s_length)
{
#ifdef HAVE_MUNLOCK
  void *	address = IK_POINTER_DATA_VOIDP(s_address);
  size_t	length  = ik_integer_to_size_t(s_length);
  int		rv;
  errno = 0;
  rv    = munlock(address, length);
  return (0 == rv)? IK_FIX(0) : ik_errno_to_code();
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_mlockall (ikptr_t s_flags)
{
#ifdef HAVE_MLOCKALL
  int		rv;
  errno = 0;
  rv    = mlockall(IK_UNFIX(s_flags));
  return (0 == rv)? IK_FIX(0) : ik_errno_to_code();
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_munlockall (void)
{
#ifdef HAVE_MUNLOCKALL
  int		rv;
  errno = 0;
  rv    = munlockall();
  return (0 == rv)? IK_FIX(0) : ik_errno_to_code();
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_mprotect (ikptr_t s_address, ikptr_t s_length, ikptr_t s_prot)
{
#ifdef HAVE_MPROTECT
  void *	address = IK_POINTER_DATA_VOIDP(s_address);
  size_t	length  = ik_integer_to_size_t(s_length);
  int		rv;
  errno = 0;
  rv    = mprotect(address, length, IK_UNFIX(s_prot));
  return (0 == rv)? IK_FIX(0) : ik_errno_to_code();
#else
  feature_failure(__func__);
#endif
}


/** --------------------------------------------------------------------
 ** Network sockets: local namespace.
 ** ----------------------------------------------------------------- */

ikptr_t
ikrt_posix_make_sockaddr_un (ikptr_t s_pathname, ikpcb_t * pcb)
{
#ifdef HAVE_STRUCT_SOCKADDR_UN
#undef SIZE
#define SIZE	(sizeof(struct sockaddr_un)+pathname_len) /* better safe than sorry */
  char *	pathname     = IK_BYTEVECTOR_DATA_CHARP(s_pathname);
  size_t	pathname_len = (size_t)IK_BYTEVECTOR_LENGTH(s_pathname);
  uint8_t	bytes[SIZE];
  struct sockaddr_un *	name = (void *)bytes;
  name->sun_family = AF_LOCAL;
  memcpy(name->sun_path, pathname, pathname_len+1);
  return ika_bytevector_from_memory_block(pcb, name, SUN_LEN(name));
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_sockaddr_un_pathname (ikptr_t s_addr, ikpcb_t * pcb)
{
#ifdef HAVE_STRUCT_SOCKADDR_UN
  struct sockaddr_un *	addr = IK_BYTEVECTOR_DATA_VOIDP(s_addr);
  if (AF_LOCAL == addr->sun_family) {
    ikptr_t	s_bv;
    size_t	len = strlen(addr->sun_path);
    void *	buf;
    pcb->root0 = &s_addr;
    {
      /* WARNING  We  do  not use  "ika_bytevector_from_cstring()"  here
	 because the C	string is embedded in the  bytevector S_ADDR and
	 we cannot preserve it by calling that function. */
      s_bv = ika_bytevector_alloc(pcb, len);
      buf  = IK_BYTEVECTOR_DATA_VOIDP(s_bv);
      addr = IK_BYTEVECTOR_DATA_VOIDP(s_addr);
      memcpy(buf, addr->sun_path, len);
    }
    pcb->root0 = NULL;
    return s_bv;
  } else
    return IK_FALSE_OBJECT;
#else
  feature_failure(__func__);
#endif
}


/** --------------------------------------------------------------------
 ** Network sockets: IPv4 namespace.
 ** ----------------------------------------------------------------- */

ikptr_t
ikrt_posix_make_sockaddr_in (ikptr_t s_host_address, ikptr_t s_port, ikpcb_t * pcb)
{
#ifdef HAVE_STRUCT_SOCKADDR_IN
#undef BV_LEN
#define BV_LEN	sizeof(struct sockaddr_in)
  ikptr_t			s_socket_address;
  pcb->root0 = &s_host_address;
  pcb->root1 = &s_port;
  {
    struct in_addr *		host_address;
    struct sockaddr_in *	socket_address;
    uint16_t			port = htons((uint16_t)IK_UNFIX(s_port));
    /* fprintf(stderr, "%s: port %ld %u\n", __func__, IK_UNFIX(s_port), port); */
    s_socket_address	       = ika_bytevector_alloc(pcb, BV_LEN);
    socket_address	       = IK_BYTEVECTOR_DATA_VOIDP(s_socket_address);
    socket_address->sin_family = AF_INET;
    socket_address->sin_port   = (unsigned short int)port;
    /* fprintf(stderr, "%s: field %u\n", __func__, (uint16_t)(ntohs(socket_address->sin_port))); */
    host_address	       = IK_BYTEVECTOR_DATA_VOIDP(s_host_address);
    /* Notice that on,  x86 platforms, the bytevector "#vu8(127  0 0 1)"
       must become  the "uint32_t sin_addr"  number in host  byte order:
       "0x7f000001". */
    memcpy(&(socket_address->sin_addr), host_address, sizeof(struct in_addr));
  }
  pcb->root1 = NULL;
  pcb->root0 = NULL;
  return s_socket_address;
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_sockaddr_in_in_addr (ikptr_t s_socket_address, ikpcb_t * pcb)
{
#ifdef HAVE_STRUCT_SOCKADDR_IN
  struct sockaddr_in *	socket_address = IK_BYTEVECTOR_DATA_VOIDP(s_socket_address);
  if (AF_INET == socket_address->sin_family) {
#undef BV_LEN
#define BV_LEN	sizeof(struct in_addr)
    ikptr_t		s_host_address;
    pcb->root0 = &s_socket_address;
    {
      struct in_addr *	host_address;
      s_host_address = ika_bytevector_alloc(pcb, BV_LEN);
      host_address   = IK_BYTEVECTOR_DATA_VOIDP(s_host_address);
      socket_address = IK_BYTEVECTOR_DATA_VOIDP(s_socket_address);
      memcpy(host_address, &(socket_address->sin_addr), BV_LEN);
    }
    pcb->root0 = NULL;
    return s_host_address;
  } else
    return IK_FALSE_OBJECT;
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_sockaddr_in_in_addr_number (ikptr_t s_socket_address, ikpcb_t * pcb)
{
#if ((defined HAVE_STRUCT_SOCKADDR_IN) && (defined HAVE_NTOHL))
  struct sockaddr_in *	socket_address = IK_BYTEVECTOR_DATA_VOIDP(s_socket_address);
  if (AF_INET == socket_address->sin_family) {
#undef BV_LEN
#define BV_LEN	sizeof(struct in_addr)
    ikptr_t		s_host_address;
    pcb->root0 = &s_socket_address;
    {
      s_host_address = ika_integer_from_uint32(pcb, ntohl(socket_address->sin_addr.s_addr));
    }
    pcb->root0 = NULL;
    return s_host_address;
  } else
    return IK_FALSE_OBJECT;
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_sockaddr_in_in_port (ikptr_t s_socket_address)
{
#ifdef HAVE_STRUCT_SOCKADDR_IN
  struct sockaddr_in *	socket_address = IK_BYTEVECTOR_DATA_VOIDP(s_socket_address);
  if (AF_INET == socket_address->sin_family) {
    uint16_t		port = ntohs((uint16_t)(socket_address->sin_port));
    /* fprintf(stderr, "%s: port %u\n", __func__, port); */
    return IK_FIX((ikuword_t)port);
  } else
    return IK_FALSE;
#else
  feature_failure(__func__);
#endif
}


/** --------------------------------------------------------------------
 ** Network sockets: IPv6 namespace.
 ** ----------------------------------------------------------------- */

ikptr_t
ikrt_posix_make_sockaddr_in6 (ikptr_t s_host_address, ikptr_t s_port, ikpcb_t * pcb)
{
#ifdef HAVE_STRUCT_SOCKADDR_IN6
#undef BV_LEN
#define BV_LEN	sizeof(struct sockaddr_in6)
  ikptr_t			s_socket_address;
  pcb->root0 = &s_host_address;
  pcb->root1 = &s_port;
  {
    struct in6_addr *		host_address;
    struct sockaddr_in6 *	socket_address;
    uint16_t			port = htons((uint16_t)IK_UNFIX(s_port));
    /* fprintf(stderr, "%s: port %ld %u\n", __func__, IK_UNFIX(s_port), port); */
    s_socket_address	        = ika_bytevector_alloc(pcb, BV_LEN);
    socket_address	        = IK_BYTEVECTOR_DATA_VOIDP(s_socket_address);
    socket_address->sin6_family = AF_INET6;
    socket_address->sin6_port   = (unsigned short int)port;
    /* fprintf(stderr, "%s: field %u\n", __func__, (uint16_t)(ntohs(socket_address->sin_port))); */
    host_address                = IK_BYTEVECTOR_DATA_VOIDP(s_host_address);
    memcpy(&(socket_address->sin6_addr), host_address, sizeof(struct in6_addr));
  }
  pcb->root1 = NULL;
  pcb->root0 = NULL;
  return s_socket_address;
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_sockaddr_in6_in6_addr (ikptr_t s_socket_address, ikpcb_t * pcb)
{
#ifdef HAVE_STRUCT_SOCKADDR_IN6
  struct sockaddr_in6 *	 socket_address = IK_BYTEVECTOR_DATA_VOIDP(s_socket_address);
  if (AF_INET6 == socket_address->sin6_family) {
#undef BV_LEN
#define BV_LEN	sizeof(struct in6_addr)
    ikptr_t		s_host_address;
    struct in6_addr *	host_address;
    pcb->root0 = &s_socket_address;
    {
      s_host_address = ika_bytevector_alloc(pcb, BV_LEN);
      host_address   = IK_BYTEVECTOR_DATA_VOIDP(s_host_address);
      socket_address = IK_BYTEVECTOR_DATA_VOIDP(s_socket_address);
      memcpy(host_address, &(socket_address->sin6_addr), BV_LEN);
    }
    pcb->root0 = NULL;
    return s_host_address;
  } else
    return IK_FALSE_OBJECT;
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_sockaddr_in6_in6_port (ikptr_t s_socket_address)
{
#ifdef HAVE_STRUCT_SOCKADDR_IN6
  struct sockaddr_in6 *	 socket_address = IK_BYTEVECTOR_DATA_VOIDP(s_socket_address);
  /* return (AF_INET6 == socket_address->sin6_family)? */
  /*   IK_FIX((ikuword_t)socket_address->sin6_port) : IK_FALSE_OBJECT; */
  if (AF_INET6 == socket_address->sin6_family) {
    uint16_t		port = ntohs((uint16_t)(socket_address->sin6_port));
    /* fprintf(stderr, "%s: port %u\n", __func__, port); */
    return IK_FIX((ikuword_t)port);
  } else
    return IK_FALSE;

#else
  feature_failure(__func__);
#endif
}

/* ------------------------------------------------------------------ */

ikptr_t
ikrt_posix_in6addr_loopback (ikpcb_t * pcb)
{
#ifdef HAVE_STRUCT_IN6_ADDR
  static const struct in6_addr constant_host_address = IN6ADDR_LOOPBACK_INIT;
  ikptr_t			s_host_address;
  struct in6_addr *	host_address;
#undef BV_LEN
#define BV_LEN		sizeof(struct in6_addr)
  s_host_address = ika_bytevector_alloc(pcb, BV_LEN);
  host_address	 = IK_BYTEVECTOR_DATA_VOIDP(s_host_address);
  memcpy(host_address, &constant_host_address, BV_LEN);
  return s_host_address;
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_in6addr_any (ikpcb_t * pcb)
{
#ifdef HAVE_STRUCT_IN6_ADDR
  static const struct in6_addr constant_host_address = IN6ADDR_ANY_INIT;
  ikptr_t			s_host_address;
  struct in6_addr *	host_address;
#undef BV_LEN
#define BV_LEN		sizeof(struct in6_addr)
  s_host_address = ika_bytevector_alloc(pcb, BV_LEN);
  host_address	 = IK_BYTEVECTOR_DATA_VOIDP(s_host_address);
  memcpy(host_address, &constant_host_address, BV_LEN);
  return s_host_address;
#else
  feature_failure(__func__);
#endif
}


/** --------------------------------------------------------------------
 ** Network address conversion functions.
 ** ----------------------------------------------------------------- */

ikptr_t
ikrt_posix_inet_aton (ikptr_t s_dotted_quad, ikpcb_t * pcb)
{
#ifdef HAVE_INET_ATON
  void *		dotted_quad;
  ikptr_t			s_host_address;
  struct in_addr *	host_address;
  int			rv;
#undef BV_LEN
#define BV_LEN		sizeof(struct in_addr)
  pcb->root0 = &s_dotted_quad;
  {
    s_host_address = ika_bytevector_alloc(pcb, BV_LEN);
    host_address   = IK_BYTEVECTOR_DATA_VOIDP(s_host_address);
    dotted_quad    = IK_BYTEVECTOR_DATA_VOIDP(s_dotted_quad);
    rv = inet_aton(dotted_quad, host_address);
  }
  pcb->root0 = NULL;
  return (0 != rv)? s_host_address : IK_FALSE_OBJECT;
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_inet_ntoa (ikptr_t s_host_address, ikpcb_t * pcb)
{
#ifdef HAVE_INET_NTOA
  struct in_addr *	host_address;
  ikptr_t			s_dotted_quad;
  char *		dotted_quad;
  char *		data;
  size_t		data_len;
  host_address  = IK_BYTEVECTOR_DATA_VOIDP(s_host_address);
  data          = inet_ntoa(*host_address);
  data_len      = strlen(data);
  /* WARNING  The string referenced  by DATA  is a  statically allocated
     buffer, so  we do  not need to  register S_HOST_ADDRESS  as garbage
     collection root while doing the following allocation. */
  s_dotted_quad = ika_bytevector_alloc(pcb, data_len);
  dotted_quad   = IK_BYTEVECTOR_DATA_CHARP(s_dotted_quad);
  memcpy(dotted_quad, data, data_len);
  pcb->root0 = NULL;
  return s_dotted_quad;
#else
  feature_failure(__func__);
#endif
}

/* ------------------------------------------------------------------ */

ikptr_t
ikrt_posix_inet_pton (ikptr_t s_af, ikptr_t s_presentation, ikpcb_t * pcb)
{
#ifdef HAVE_INET_PTON
  void *	presentation;
  ikptr_t		s_host_address;
  int		rv;
  switch (IK_UNFIX(s_af)) {
  case AF_INET:
    {
#undef BV_LEN
#define BV_LEN		sizeof(struct in_addr)
      struct in_addr *	    host_address;
      pcb->root0 = &s_presentation;
      {
	s_host_address = ika_bytevector_alloc(pcb, BV_LEN);
	host_address   = IK_BYTEVECTOR_DATA_VOIDP(s_host_address);
	presentation   = IK_BYTEVECTOR_DATA_VOIDP(s_presentation);
	rv = inet_pton(IK_UNFIX(s_af), presentation, host_address);
      }
      pcb->root0 = NULL;
      return (0 < rv)? s_host_address : IK_FALSE_OBJECT;
    }
  case AF_INET6:
    {
#undef BV_LEN
#define BV_LEN		sizeof(struct in6_addr)
      struct in6_addr *	     host_address;
      pcb->root0 = &s_presentation;
      {
	s_host_address = ika_bytevector_alloc(pcb, BV_LEN);
	host_address   = IK_BYTEVECTOR_DATA_VOIDP(s_host_address);
	presentation   = IK_BYTEVECTOR_DATA_VOIDP(s_presentation);
	rv = inet_pton(IK_UNFIX(s_af), presentation, host_address);
      }
      pcb->root0 = NULL;
      return (0 < rv)? s_host_address : IK_FALSE_OBJECT;
    }
  default:
    return IK_FALSE_OBJECT;
  }
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_inet_ntop (ikptr_t s_af, ikptr_t s_host_address, ikpcb_t * pcb)
{
#ifdef HAVE_INET_NTOP
  switch (IK_UNFIX(s_af)) {
  case AF_INET:
  case AF_INET6:
    {
      void *		host_address;
      socklen_t		buflen = 256;
      char		buffer[buflen];
      const char *	rv;
      host_address = IK_BYTEVECTOR_DATA_VOIDP(s_host_address);
      rv = inet_ntop(IK_UNFIX(s_af), host_address, buffer, buflen);
      if (NULL != rv) {
	ikptr_t	  s_presentation;
	char *	  presentation;
	size_t	  presentation_len;
	presentation_len = strlen(buffer);
	s_presentation	 = ika_bytevector_alloc(pcb, presentation_len);
	presentation	 = IK_BYTEVECTOR_DATA_CHARP(s_presentation);
	memcpy(presentation, buffer, presentation_len);
	return s_presentation;
      } else
	return IK_FALSE_OBJECT;
    }
  default:
    return IK_FALSE_OBJECT;
  }
#else
  feature_failure(__func__);
#endif
}


/** --------------------------------------------------------------------
 ** Host names database.
 ** ----------------------------------------------------------------- */

#ifdef HAVE_STRUCT_HOSTENT
static ikptr_t
hostent_to_struct (ikptr_t s_rtd, struct hostent * src, ikpcb_t * pcb)
/* Convert  a  C  language  "struct  hostent"  into  a  Scheme  language
   "struct-hostent".  Makes use of "pcb->root6,7,8". */
{
  ikptr_t s_dst = ika_struct_alloc_and_init(pcb, s_rtd); /* this uses "pcb->root9" */
  pcb->root8 = &s_dst;
  { /* store the official host name */
    IK_ASS(IK_FIELD(s_dst, 0), ika_bytevector_from_cstring(pcb, src->h_name));
    IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_FIELD_PTR(s_dst, 0));
  }
  { /* store the list of aliases */
    if (src->h_aliases[0]) {
      ikptr_t	s_list_of_aliases, s_spine;
      s_list_of_aliases = s_spine = ika_pair_alloc(pcb);
      pcb->root6 = &s_list_of_aliases;
      pcb->root7 = &s_spine;
      {
	int	i;
	for (i=0; src->h_aliases[i];) {
	  IK_ASS(IK_CAR(s_spine), ika_bytevector_from_cstring(pcb, src->h_aliases[i]));
	  IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_CAR_PTR(s_spine));
	  if (src->h_aliases[++i]) {
	    IK_ASS(IK_CDR(s_spine), ika_pair_alloc(pcb));
	    IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_CDR_PTR(s_spine));
	    s_spine = IK_CDR(s_spine);
	  } else {
	    IK_CDR(s_spine) = IK_NULL_OBJECT;
	    break;
	  }
	}
      }
      pcb->root7 = NULL;
      pcb->root6 = NULL;
      IK_FIELD(s_dst, 1) = s_list_of_aliases;
    } else {
      IK_FIELD(s_dst, 1) = IK_NULL_OBJECT;
    }
  }
  { /* store the host address type */
    IK_FIELD(s_dst, 2) = IK_FIX(src->h_addrtype);
  }
  { /* store the host address structure length */
    IK_FIELD(s_dst, 3) = IK_FIX(src->h_length);
  }
  { /* store the reversed list of addresses */
    if (src->h_addr_list[0]) {
      ikptr_t	s_list_of_addrs, s_spine;
      s_list_of_addrs = s_spine = ika_pair_alloc(pcb);
      pcb->root6 = &s_list_of_addrs;
      pcb->root7 = &s_spine;
      {
	int	i;
	for (i=0; src->h_addr_list[i];) {
	  IK_ASS(IK_CAR(s_spine), ika_bytevector_from_memory_block(pcb, src->h_addr_list[i], src->h_length));
	  IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_CAR_PTR(s_spine));
	  if (src->h_addr_list[++i]) {
	    IK_ASS(IK_CDR(s_spine), ika_pair_alloc(pcb));
	    IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_CDR_PTR(s_spine));
	    s_spine = IK_CDR(s_spine);
	  } else {
	    IK_CDR(s_spine) = IK_NULL_OBJECT;
	    break;
	  }
	}
      }
      pcb->root7 = NULL;
      pcb->root6 = NULL;
      IK_FIELD(s_dst, 4) = s_list_of_addrs;
      IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_FIELD_PTR(s_dst, 4));
    } else
      IK_FIELD(s_dst, 4) = IK_NULL_OBJECT;
  }
  {/* store the first in the list of addresses */
    IK_FIELD(s_dst, 5) = IK_CAR(IK_FIELD(s_dst, 4));
    IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_FIELD_PTR(s_dst, 5));
  }
  pcb->root8 = NULL;
  return s_dst;
}
#endif
ikptr_t
ikrt_posix_gethostbyname (ikptr_t s_rtd, ikptr_t s_hostname, ikpcb_t * pcb)
{
#ifdef HAVE_GETHOSTBYNAME
  char *		hostname;
  struct hostent *	rv;
  hostname = IK_BYTEVECTOR_DATA_CHARP(s_hostname);
  errno	   = 0;
  h_errno  = 0;
  rv	   = gethostbyname(hostname);
  return (NULL != rv)? hostent_to_struct(s_rtd, rv, pcb) : IK_FIX(-h_errno);
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_gethostbyname2 (ikptr_t s_rtd, ikptr_t s_hostname, ikptr_t s_af, ikpcb_t * pcb)
{
#ifdef HAVE_GETHOSTBYNAME2
  char *		hostname;
  struct hostent *	rv;
  hostname = IK_BYTEVECTOR_DATA_CHARP(s_hostname);
  errno	   = 0;
  h_errno  = 0;
  rv	   = gethostbyname2(hostname, IK_UNFIX(s_af));
  return (NULL != rv)? hostent_to_struct(s_rtd, rv, pcb) : IK_FIX(-h_errno);
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_gethostbyaddr (ikptr_t s_rtd, ikptr_t s_host_address, ikpcb_t * pcb)
{
#ifdef HAVE_GETHOSTBYADDR
  void *		host_address;
  size_t		host_address_len;
  int			format;
  struct hostent *	rv;
  host_address	   = IK_BYTEVECTOR_DATA_VOIDP(s_host_address);
  host_address_len = (size_t)IK_BYTEVECTOR_LENGTH(s_host_address);
  format   = (sizeof(struct in_addr) == host_address_len)? AF_INET : AF_INET6;
  errno	   = 0;
  h_errno  = 0;
  rv	   = gethostbyaddr(host_address, host_address_len, format);
  return (NULL != rv)? hostent_to_struct(s_rtd, rv, pcb) : IK_FIX(-h_errno);
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_host_entries (ikptr_t s_rtd, ikpcb_t * pcb)
{
#if ((defined HAVE_SETHOSTENT) && (defined HAVE_GETHOSTENT) && (defined HAVE_ENDHOSTENT))
  struct hostent *	entry;
  ikptr_t			s_list_of_entries;
  sethostent(1);
  {
    entry = gethostent();
    if (entry) {
      ikptr_t	s_spine;
      pcb->root0 = &s_rtd;
      {
	s_spine = s_list_of_entries = ika_pair_alloc(pcb);
	pcb->root1 = &s_list_of_entries;
	pcb->root2 = &s_spine;
	{
	  while (entry) {
	    IK_ASS(IK_CAR(s_spine), hostent_to_struct(s_rtd, entry, pcb));
	    IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_CAR_PTR(s_spine));
	    entry = gethostent();
	    if (entry) {
	      IK_ASS(IK_CDR(s_spine), ika_pair_alloc(pcb));
	      IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_CDR_PTR(s_spine));
	      s_spine = IK_CDR(s_spine);
	    } else {
	      IK_CDR(s_spine) = IK_NULL_OBJECT;
	      break;
	    }
	  }
	}
	pcb->root2 = NULL;
	pcb->root1 = NULL;
      }
      pcb->root0 = NULL;
    } else
      s_list_of_entries = IK_NULL_OBJECT;
  }
  endhostent();
  return s_list_of_entries;
#else
  feature_failure(__func__);
#endif
}


/** --------------------------------------------------------------------
 ** Network address informations.
 ** ----------------------------------------------------------------- */

#if ((defined HAVE_STRUCT_ADDRINFO) && (defined HAVE_GETADDRINFO))
static ikptr_t
addrinfo_to_struct (ikpcb_t * pcb, ikptr_t s_rtd, struct addrinfo * src, int with_canon_name)
/* Convert  a  C  language  "struct  addrinfo" into  a  Scheme  language
   "struct-addrinfo".  Make use of "pcb->root9". */
{
  ikptr_t s_dst = ika_struct_alloc_and_init(pcb, s_rtd); /* this uses "pcb->root9" */
  pcb->root9 = &s_dst;
  {
    IK_ASS(IK_FIELD(s_dst, 0), IK_FIX(src->ai_flags));
    IK_ASS(IK_FIELD(s_dst, 1), IK_FIX(src->ai_family));
    IK_ASS(IK_FIELD(s_dst, 2), IK_FIX(src->ai_socktype));
    IK_ASS(IK_FIELD(s_dst, 3), IK_FIX(src->ai_protocol));
    IK_ASS(IK_FIELD(s_dst, 4), IK_FIX(src->ai_addrlen));
    /* fill the field "ai_addr" */
    IK_ASS(IK_FIELD(s_dst, 5), ika_bytevector_from_memory_block(pcb, src->ai_addr, src->ai_addrlen));
    IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_FIELD_PTR(s_dst, 5));
    /* fill the field "ai_canonname" */
    if (with_canon_name && src->ai_canonname) {
      IK_ASS(IK_FIELD(s_dst, 6), ika_bytevector_from_cstring(pcb, src->ai_canonname));
      IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_FIELD_PTR(s_dst, 6));
    } else
      IK_FIELD(s_dst, 6) = IK_FALSE_OBJECT;
  }
  pcb->root9 = NULL;
  return s_dst;
}
#endif
ikptr_t
ikrt_posix_getaddrinfo (ikptr_t s_rtd, ikptr_t s_node, ikptr_t s_service, ikptr_t s_hints_struct, ikpcb_t * pcb)
{
#if ((defined HAVE_STRUCT_ADDRINFO) && (defined HAVE_GETADDRINFO))
  const char *		node;
  const char *		service;
  struct addrinfo	hints;
  struct addrinfo *	hints_p;
  struct addrinfo *	result;
  struct addrinfo *	iter;
  int			rv, with_canon_name;
  node	  = (IK_FALSE_OBJECT != s_node)?    IK_BYTEVECTOR_DATA_CHARP(s_node)    : NULL;
  service = (IK_FALSE_OBJECT != s_service)? IK_BYTEVECTOR_DATA_CHARP(s_service) : NULL;
  memset(&hints, '\0', sizeof(struct addrinfo));
  if (IK_FALSE_OBJECT == s_hints_struct) {
    hints_p		= NULL;
    with_canon_name	= 0;
  } else {
    hints_p		= &hints;
    hints.ai_flags	= IK_UNFIX(IK_FIELD(s_hints_struct, 0));
    hints.ai_family	= IK_UNFIX(IK_FIELD(s_hints_struct, 1));
    hints.ai_socktype	= IK_UNFIX(IK_FIELD(s_hints_struct, 2));
    hints.ai_protocol	= IK_UNFIX(IK_FIELD(s_hints_struct, 3));
    with_canon_name	= AI_CANONNAME & hints.ai_flags;
  }
  rv = getaddrinfo(node, service, hints_p, &result);
  if (0 == rv) {
    ikptr_t	s_list_of_addrinfo;
    if (result) {
      pcb->root0 = &s_rtd;
      {
	ikptr_t	s_spine;
	s_list_of_addrinfo = s_spine = ika_pair_alloc(pcb);
	pcb->root1 = &s_list_of_addrinfo;
	pcb->root2 = &s_spine;
	{
	  for (iter = result; iter;) {
	    IK_ASS(IK_CAR(s_spine), addrinfo_to_struct(pcb, s_rtd, iter, with_canon_name));
	    IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_CAR_PTR(s_spine));
	    iter = iter->ai_next;
	    if (iter) {
	      IK_ASS(IK_CDR(s_spine), ika_pair_alloc(pcb));
	      IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_CDR_PTR(s_spine));
	      s_spine = IK_CDR(s_spine);
	    } else {
	      IK_CDR(s_spine) = IK_NULL_OBJECT;
	      break;
	    }
	  }
	}
	pcb->root2 = NULL;
	pcb->root1 = NULL;
      }
      pcb->root0 = NULL;
      freeaddrinfo(result);
    } else
      s_list_of_addrinfo = IK_NULL_OBJECT;
    return s_list_of_addrinfo;
  } else {
    /* The  GAI_  codes	 are  already  negative in  the	 GNU  C	 Library
       headers. */
    return IK_FIX(rv);
  }
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_gai_strerror (ikptr_t s_error_code, ikpcb_t * pcb)
{
#ifdef HAVE_GAI_STRERROR
  return ika_bytevector_from_cstring(pcb, gai_strerror(IK_UNFIX(s_error_code)));
#else
  feature_failure(__func__);
#endif
}


/** --------------------------------------------------------------------
 ** Network protocols database.
 ** ----------------------------------------------------------------- */

#ifdef HAVE_STRUCT_PROTOENT
static ikptr_t
protoent_to_struct (ikpcb_t * pcb, ikptr_t s_rtd, struct protoent * src)
/* Convert  a  C  language  "struct  protoent" into  a  Scheme  language
   "struct-protoent".  Make use of "pcb->root7,8,9". */
{
  ikptr_t s_dst = ika_struct_alloc_and_init(pcb, s_rtd); /* this uses "pcb->root9" */
  pcb->root9 = &s_dst;
  {
    /* fill the field "p_name" */
    IK_ASS(IK_FIELD(s_dst, 0), ika_bytevector_from_cstring(pcb, src->p_name));
    IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_FIELD_PTR(s_dst, 0));
    /* fill the field "p_aliases" */
    if (src->p_aliases[0]) {
      ikptr_t	s_list_of_aliases, s_spine;
      int	i;
      s_list_of_aliases = s_spine = ika_pair_alloc(pcb);
      pcb->root8 = &s_list_of_aliases;
      pcb->root7 = &s_spine;
      {
	for (i=0; src->p_aliases[i];) {
	  IK_ASS(IK_CAR(s_spine), ika_bytevector_from_cstring(pcb, src->p_aliases[i]));
	  IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_CAR_PTR(s_spine));
	  if (src->p_aliases[++i]) {
	    IK_ASS(IK_CDR(s_spine), ika_pair_alloc(pcb));
	    IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_CDR_PTR(s_spine));
	    s_spine = IK_CDR(s_spine);
	  } else {
	    IK_CDR(s_spine) = IK_NULL_OBJECT;
	    break;
	  }
	}
      }
      pcb->root7 = NULL;
      pcb->root8 = NULL;
      IK_FIELD(s_dst, 1) = s_list_of_aliases;
      IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_FIELD_PTR(s_dst, 1));
    } else
      IK_FIELD(s_dst, 1) = IK_NULL_OBJECT;
    /* fill the field "p_proto" */
    IK_FIELD(s_dst, 2) = IK_FIX(src->p_proto);
  }
  pcb->root9 = NULL;
  return s_dst;
}
#endif
ikptr_t
ikrt_posix_getprotobyname (ikptr_t s_rtd, ikptr_t s_name, ikpcb_t * pcb)
{
#ifdef HAVE_GETPROTOBYNAME
  char *		name;
  struct protoent *	entry;
  name	= IK_BYTEVECTOR_DATA_CHARP(s_name);
  entry = getprotobyname(name);
  return (entry)? protoent_to_struct(pcb, s_rtd, entry) : IK_FALSE_OBJECT;
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_getprotobynumber (ikptr_t s_rtd, ikptr_t s_proto_num, ikpcb_t * pcb)
{
#ifdef HAVE_GETPROTOBYNUMBER
  struct protoent *	entry;
  entry = getprotobynumber(IK_UNFIX(s_proto_num));
  return (entry)? protoent_to_struct(pcb, s_rtd, entry) : IK_FALSE_OBJECT;
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_protocol_entries (ikptr_t s_rtd, ikpcb_t * pcb)
{
#if ((defined HAVE_SETPROTOENT) && (defined HAVE_GETPROTOENT) && (defined ENDPROTOENT))
  ikptr_t			s_list_of_entries;
  struct protoent *	entry;
  setprotoent(1);
  {
    pcb->root0 = &s_rtd;
    {
      entry = getprotoent();
      if (entry) {
	ikptr_t	s_spine;
	s_list_of_entries = s_spine = ika_pair_alloc(pcb);
	pcb->root1 = &s_list_of_entries;
	pcb->root2 = &s_spine;
	{
	  while (entry) {
	    IK_ASS(IK_CAR(s_spine), protoent_to_struct(pcb, s_rtd, entry));
	    IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_CAR_PTR(s_spine));
	    entry = getprotoent();
	    if (entry) {
	      IK_ASS(IK_CDR(s_spine), ika_pair_alloc(pcb));
	      IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_CDR_PTR(s_spine));
	      s_spine = IK_CDR(s_spine);
	    } else {
	      IK_CDR(s_spine) = IK_NULL_OBJECT;
	      break;
	    }
	  }
	}
	pcb->root2 = NULL;
	pcb->root1 = NULL;
      } else
	s_list_of_entries = IK_NULL_OBJECT;
    }
    pcb->root0 = NULL;
  }
  endprotoent();
  return s_list_of_entries;
#else
  feature_failure(__func__);
#endif
}


/** --------------------------------------------------------------------
 ** Network services database.
 ** ----------------------------------------------------------------- */

#ifdef HAVE_STRUCT_SERVENT
static ikptr_t
servent_to_struct (ikpcb_t * pcb, ikptr_t s_rtd, struct servent * src)
/* Convert  a  C  language  "struct  servent"  into  a  Scheme  language
   "struct-servent". Make use of "pcb->root7,8,9". */
{
  ikptr_t s_dst = ika_struct_alloc_and_init(pcb, s_rtd); /* this uses "pcb->root9" */
  pcb->root9 = &s_dst;
  {
    /* fill the field "s_name" */
    IK_ASS(IK_FIELD(s_dst, 0), ika_bytevector_from_cstring(pcb, src->s_name));
    IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_FIELD_PTR(s_dst, 0));
    /* fill the field "s_aliases" */
    if (src->s_aliases[0]) {
      ikptr_t	s_list_of_aliases, s_spine;
      int	i;
      s_list_of_aliases = s_spine = ika_pair_alloc(pcb);
      pcb->root8 = &s_list_of_aliases;
      pcb->root7 = &s_spine;
      {
	for (i=0; src->s_aliases[i];) {
	  IK_ASS(IK_CAR(s_spine), ika_bytevector_from_cstring(pcb, src->s_aliases[i]));
	  IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_CAR_PTR(s_spine));
	  if (src->s_aliases[++i]) {
	    IK_ASS(IK_CDR(s_spine), ika_pair_alloc(pcb));
	    IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_CDR_PTR(s_spine));
	    s_spine = IK_CDR(s_spine);
	  } else {
	    IK_CDR(s_spine) = IK_NULL_OBJECT;
	    break;
	  }
	}
      }
      pcb->root7 = NULL;
      pcb->root8 = NULL;
      IK_FIELD(s_dst, 1) = s_list_of_aliases;
      IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_FIELD_PTR(s_dst, 1));
    } else
      IK_FIELD(s_dst, 1) = IK_NULL_OBJECT;
    /* fill the field "s_port" */
    IK_FIELD(s_dst, 2) = IK_FIX(ntohs((uint16_t)(src->s_port)));
    /* fill the field "s_proto" */
    IK_ASS(IK_FIELD(s_dst, 3), ika_bytevector_from_cstring(pcb, src->s_proto));
    IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_FIELD_PTR(s_dst, 3));
  }
  pcb->root9 = NULL;
  return s_dst;
}
#endif
ikptr_t
ikrt_posix_getservbyname (ikptr_t s_rtd, ikptr_t s_name, ikptr_t s_proto, ikpcb_t * pcb)
{
#ifdef HAVE_GETSERVBYNAME
  char *		name;
  char *		proto;
  struct servent *	entry;
  name	= IK_BYTEVECTOR_DATA_CHARP(s_name);
  proto = IK_BYTEVECTOR_DATA_CHARP(s_proto);
  entry = getservbyname(name, proto);
  return (entry)? servent_to_struct(pcb, s_rtd, entry) : IK_FALSE_OBJECT;
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_getservbyport (ikptr_t s_rtd, ikptr_t s_port, ikptr_t s_proto, ikpcb_t * pcb)
{
#ifdef HAVE_GETSERVBYPORT
  char *		proto;
  struct servent *	entry;
  proto = IK_BYTEVECTOR_DATA_CHARP(s_proto);
  entry = getservbyport((int)htons((uint16_t)IK_UNFIX(s_port)), proto);
  return (entry)? servent_to_struct(pcb, s_rtd, entry) : IK_FALSE_OBJECT;
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_service_entries (ikptr_t s_rtd, ikpcb_t * pcb)
{
#if ((defined HAVE_SETSERVENT) && (defined HAVE_GETSERVENT) && (defined HAVE_ENDSERVENT))
  ikptr_t			s_list_of_entries;
  struct servent *	entry;
  setservent(1);
  {
    entry = getservent();
    if (entry) {
      pcb->root0 = &s_rtd;
      {
	ikptr_t	s_spine;
	s_list_of_entries = s_spine = ika_pair_alloc(pcb);
	pcb->root1 = &s_list_of_entries;
	pcb->root2 = &s_spine;
	{
	  while (entry) {
	    IK_ASS(IK_CAR(s_spine), servent_to_struct(pcb, s_rtd, entry));
	    IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_CAR_PTR(s_spine));
	    entry = getservent();
	    if (entry) {
	      IK_ASS(IK_CDR(s_spine), ika_pair_alloc(pcb));
	      IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_CDR_PTR(s_spine));
	      s_spine = IK_CDR(s_spine);
	    } else {
	      IK_CDR(s_spine) = IK_NULL_OBJECT;
	      break;
	    }
	  }
	}
	pcb->root2 = NULL;
	pcb->root1 = NULL;
      }
      pcb->root0 = NULL;
    } else
      s_list_of_entries = IK_NULL_OBJECT;
  }
  endservent();
  return s_list_of_entries;
#else
  feature_failure(__func__);
#endif
}


/** --------------------------------------------------------------------
 ** Networks database.
 ** ----------------------------------------------------------------- */

#ifdef HAVE_STRUCT_NETENT
static ikptr_t
netent_to_struct (ikpcb_t * pcb, ikptr_t s_rtd, struct netent * src)
/* Convert  a  C  language   "struct  netent"  into  a  Scheme  language
   "struct-netent".  Make use of "pcb->root7,8,9". */
{
  ikptr_t s_dst = ika_struct_alloc_and_init(pcb, s_rtd); /* this uses "pcb->root9" */
  pcb->root9 = &s_dst;
  {
    IK_ASS(IK_FIELD(s_dst, 0), ika_bytevector_from_cstring(pcb, src->n_name));
    IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_FIELD_PTR(s_dst, 0));
    if (src->n_aliases[0]) {
      ikptr_t	s_list_of_aliases, s_spine;
      int	i;
      s_list_of_aliases = s_spine = ika_pair_alloc(pcb);
      pcb->root8 = &s_list_of_aliases;
      pcb->root7 = &s_spine;
      {
	for (i=0; src->n_aliases[i];) {
	  IK_ASS(IK_CAR(s_spine), ika_bytevector_from_cstring(pcb, src->n_aliases[i]));
	  IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_CAR_PTR(s_spine));
	  if (src->n_aliases[++i]) {
	    IK_ASS(IK_CDR(s_spine), ika_pair_alloc(pcb));
	    IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_CDR_PTR(s_spine));
	    s_spine = IK_CDR(s_spine);
	  } else {
	    IK_CDR(s_spine) = IK_NULL_OBJECT;
	    break;
	  }
	}
      }
      pcb->root7 = NULL;
      pcb->root8 = NULL;
      IK_FIELD(s_dst, 1) = s_list_of_aliases;
      IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_FIELD_PTR(s_dst, 1));
    } else
      IK_FIELD(s_dst, 1) = IK_NULL_OBJECT;
    IK_FIELD(s_dst, 2) = IK_FIX(src->n_addrtype);
    IK_ASS(IK_FIELD(s_dst, 3), ika_integer_from_ullong(pcb, (ik_ullong)src->n_net));
    IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_FIELD_PTR(s_dst, 3));
  }
  pcb->root9 = NULL;
  return s_dst;
}
#endif
ikptr_t
ikrt_posix_getnetbyname (ikptr_t s_rtd, ikptr_t s_name, ikpcb_t * pcb)
{
#ifdef HAVE_GETNETBYNAME
  char *		name;
  struct netent *	entry;
  name	= IK_BYTEVECTOR_DATA_CHARP(s_name);
  entry = getnetbyname(name);
  return (entry)? netent_to_struct(pcb, s_rtd, entry) : IK_FALSE_OBJECT;
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_getnetbyaddr (ikptr_t s_rtd, ikptr_t s_net_num, ikptr_t s_type, ikpcb_t * pcb)
{
#ifdef HAVE_GETNETBYADDR
  uint32_t		net;
  struct netent *	entry;
  net   = (uint32_t)ik_integer_to_uint(s_net_num);
  entry = getnetbyaddr(net, IK_UNFIX(s_type));
  return (entry)? netent_to_struct(pcb, s_rtd, entry) : IK_FALSE_OBJECT;
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_network_entries (ikptr_t s_rtd, ikpcb_t * pcb)
{
#if ((defined HAVE_SETNETENT) && (defined HAVE_GETNETENT) && (defined HAVE_ENDNETENT))
  struct netent *	entry;
  ikptr_t			s_list_of_entries;
  setnetent(1);
  entry = getnetent();
  if (entry) {
    pcb->root0 = &s_rtd;
    {
      ikptr_t	s_spine;
      s_list_of_entries = s_spine = ika_pair_alloc(pcb);
      pcb->root1 = &s_list_of_entries;
      pcb->root2 = &s_spine;
      {
	while (entry) {
	  IK_ASS(IK_CAR(s_spine), netent_to_struct(pcb, s_rtd, entry));
	  IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_CAR_PTR(s_spine));
	  entry = getnetent();
	  if (entry) {
	    IK_ASS(IK_CDR(s_spine), ika_pair_alloc(pcb));
	    IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_CDR_PTR(s_spine));
	    s_spine = IK_CDR(s_spine);
	  } else {
	    IK_CDR(s_spine) = IK_NULL_OBJECT;
	    break;
	  }
	}
      }
      pcb->root2 = NULL;
      pcb->root1 = NULL;
    }
    pcb->root0 = NULL;
  } else
    s_list_of_entries = IK_NULL_OBJECT;
  endnetent();
  return s_list_of_entries;
#else
  feature_failure(__func__);
#endif
}


/** --------------------------------------------------------------------
 ** Network socket constructors.
 ** ----------------------------------------------------------------- */

ikptr_t
ikrt_posix_socket (ikptr_t s_namespace, ikptr_t s_style, ikptr_t s_protocol)
{
#ifdef HAVE_SOCKET
  int	rv;
  errno = 0;
  rv	= socket(IK_UNFIX(s_namespace), IK_UNFIX(s_style), IK_UNFIX(s_protocol));
  return (0 <= rv)? IK_FIX(rv) : ik_errno_to_code();
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_shutdown (ikptr_t s_sock, ikptr_t s_how)
{
#ifdef HAVE_SHUTDOWN
  int	rv;
  errno = 0;
  rv	= shutdown(IK_NUM_TO_FD(s_sock), IK_UNFIX(s_how));
  return (0 == rv)? IK_FIX(0) : ik_errno_to_code();
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_socketpair (ikptr_t s_namespace, ikptr_t s_style, ikptr_t s_protocol, ikpcb_t * pcb)
{
#ifdef HAVE_SOCKETPAIR
  int	rv;
  int	fds[2];
  errno = 0;
  rv	= socketpair(IK_UNFIX(s_namespace), IK_UNFIX(s_style), IK_UNFIX(s_protocol), fds);
  if (0 == rv) {
    ikptr_t	s_pair = ika_pair_alloc(pcb);
    pcb->root0 = &s_pair;
    {
      /* No need to update the  dirty vector about "s_pair", because the
	 values are fixnums. */
      IK_CAR(s_pair) = IK_FD_TO_NUM(fds[0]);
      IK_CDR(s_pair) = IK_FD_TO_NUM(fds[1]);
    }
    pcb->root0 = NULL;
    return s_pair;
  } else
    return ik_errno_to_code();
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_connect (ikptr_t s_sock, ikptr_t s_addr)
{
#ifdef HAVE_CONNECT
  struct sockaddr *	addr;
  socklen_t		addr_len;
  int			rv;
  addr	   = IK_BYTEVECTOR_DATA_VOIDP(s_addr);
  addr_len = (socklen_t)IK_BYTEVECTOR_LENGTH(s_addr);
  errno	   = 0;
  rv	   = connect(IK_NUM_TO_FD(s_sock), addr, addr_len);
  return (0 == rv)? IK_FIX(0) : ik_errno_to_code();
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_listen (ikptr_t s_sock, ikptr_t s_number_of_pending_connections)
{
#ifdef HAVE_LISTEN
  int	rv;
  errno	   = 0;
  rv	   = listen(IK_NUM_TO_FD(s_sock), IK_UNFIX(s_number_of_pending_connections));
  return (0 == rv)? IK_FIX(0) : ik_errno_to_code();
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_accept (ikptr_t s_sock, ikpcb_t * pcb)
{
#ifdef HAVE_ACCEPT
#undef SIZE
#define SIZE		512
  uint8_t		bytes[SIZE];
  struct sockaddr *	addr = (struct sockaddr *)bytes;
  socklen_t		addr_len = SIZE;
  int			rv;
  errno	   = 0;
  rv	   = accept(IK_NUM_TO_FD(s_sock), addr, &addr_len);
  if (0 <= rv) {
    ikptr_t	s_pair;
    ikptr_t	s_addr;
    void *	addr_data;
    s_pair     = ika_pair_alloc(pcb);
    pcb->root0 = &s_pair;
    {
      s_addr	 = ika_bytevector_alloc(pcb, addr_len);
      addr_data	 = IK_BYTEVECTOR_DATA_VOIDP(s_addr);
      memcpy(addr_data, addr, addr_len);
      IK_CAR(s_pair) = IK_FIX(rv);
      IK_CDR(s_pair) = s_addr;
      IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_CDR_PTR(s_pair));
    }
    pcb->root0 = NULL;
    return s_pair;
  } else
    return ik_errno_to_code();
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_bind (ikptr_t s_sock, ikptr_t s_socks_addr)
{
#ifdef HAVE_BIND
  struct sockaddr *	addr;
  socklen_t		len;
  int			rv;
  addr	= IK_BYTEVECTOR_DATA_VOIDP(s_socks_addr);
  len	= (socklen_t)IK_BYTEVECTOR_LENGTH(s_socks_addr);
  errno = 0;
  rv	= bind(IK_NUM_TO_FD(s_sock), addr, len);
  return (0 == rv)? IK_FIX(0) : ik_errno_to_code();
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_getpeername (ikptr_t s_sock, ikpcb_t * pcb)
{
#ifdef HAVE_GETPEERNAME
#undef SIZE
#define SIZE		512
  uint8_t		bytes[SIZE];
  struct sockaddr *	addr = (struct sockaddr *)bytes;
  socklen_t		addr_len = SIZE;
  int			rv;
  errno	   = 0;
  rv	   = getpeername(IK_NUM_TO_FD(s_sock), addr, &addr_len);
  if (0 == rv)
    return ika_bytevector_from_memory_block(pcb, addr, addr_len);
  else
    return ik_errno_to_code();
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_getsockname (ikptr_t s_sock, ikpcb_t * pcb)
{
#ifdef HAVE_GETSOCKNAME
#undef SIZE
#define SIZE		512
  uint8_t		bytes[SIZE];
  struct sockaddr *	addr = (struct sockaddr *)bytes;
  socklen_t		addr_len = SIZE;
  int			rv;
  errno = 0;
  rv	= getsockname(IK_NUM_TO_FD(s_sock), addr, &addr_len);
  if (0 == rv)
    return ika_bytevector_from_memory_block(pcb, addr, addr_len);
  else
    return ik_errno_to_code();
#else
  feature_failure(__func__);
#endif
}


/** --------------------------------------------------------------------
 ** Network sockets: sending and receiving data.
 ** ----------------------------------------------------------------- */

ikptr_t
ikrt_posix_send (ikptr_t s_sock, ikptr_t s_buffer, ikptr_t s_size, ikptr_t s_flags)
{
#ifdef HAVE_SEND
  void *	buffer;
  size_t	size;
  int		rv;
  buffer  = IK_GENERALISED_C_BUFFER(s_buffer);
  size    = ik_generalised_c_buffer_len(s_buffer, s_size);
  errno	  = 0;
  rv	  = send(IK_NUM_TO_FD(s_sock), buffer, size, IK_UNFIX(s_flags));
  return (0 <= rv)? IK_FIX(rv) : ik_errno_to_code();
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_recv (ikptr_t s_sock, ikptr_t s_buffer, ikptr_t s_size, ikptr_t s_flags)
{
#ifdef HAVE_RECV
  void *	buffer;
  size_t	size;
  int		rv;
  buffer = IK_GENERALISED_C_BUFFER(s_buffer);
  size   = ik_generalised_c_buffer_len(s_buffer, s_size);
  errno	 = 0;
  rv	 = recv(IK_NUM_TO_FD(s_sock), buffer, size, IK_UNFIX(s_flags));
  return (0 <= rv)? IK_FIX(rv) : ik_errno_to_code();
#else
  feature_failure(__func__);
#endif
}

/* ------------------------------------------------------------------ */

ikptr_t
ikrt_posix_sendto (ikptr_t s_sock, ikptr_t s_buffer, ikptr_t s_size, ikptr_t s_flags, ikptr_t s_addr)
{
#ifdef HAVE_SENDTO
  void *		buffer;
  size_t		size;
  struct sockaddr *	addr;
  socklen_t		addr_len;
  int			rv;
  buffer   = IK_GENERALISED_C_BUFFER(s_buffer);
  size     = ik_generalised_c_buffer_len(s_buffer, s_size);
  addr	   = IK_BYTEVECTOR_DATA_VOIDP(s_addr);
  addr_len = (socklen_t)IK_BYTEVECTOR_LENGTH(s_addr);
  errno	   = 0;
  rv	   = sendto(IK_NUM_TO_FD(s_sock), buffer, size, IK_UNFIX(s_flags), addr, addr_len);
  return (0 <= rv)? IK_FIX(rv) : ik_errno_to_code();
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_recvfrom (ikptr_t s_sock, ikptr_t s_buffer, ikptr_t s_size, ikptr_t s_flags, ikpcb_t * pcb)
{
#ifdef HAVE_RECVFROM
#undef SIZE
#define SIZE		512
  uint8_t		bytes[SIZE];
  struct sockaddr *	addr = (struct sockaddr *)bytes;
  socklen_t		addr_len = SIZE;
  void *		buffer;
  size_t		size;
  int			rv;
  buffer = IK_GENERALISED_C_BUFFER(s_buffer);
  size   = ik_generalised_c_buffer_len(s_buffer, s_size);
  errno	 = 0;
  rv	 = recvfrom(IK_NUM_TO_FD(s_sock), buffer, size, IK_UNFIX(s_flags), addr, &addr_len);
  if (0 <= rv) {
    ikptr_t	s_pair = ika_pair_alloc(pcb);
    ikptr_t	s_addr;
    void *	addr_data;
    pcb->root0 = &s_pair;
    {
      s_addr	= ika_bytevector_alloc(pcb, addr_len);
      addr_data = IK_BYTEVECTOR_DATA_VOIDP(s_addr);
      memcpy(addr_data, addr, addr_len);
      IK_CAR(s_pair) = IK_FIX(rv);
      IK_CDR(s_pair) = s_addr;
      IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_CDR_PTR(s_pair));
    }
    pcb->root0 = NULL;
    return s_pair;
  } else
    return ik_errno_to_code();
#else
  feature_failure(__func__);
#endif
}


/** --------------------------------------------------------------------
 ** Network socket options.
 ** ----------------------------------------------------------------- */

ikptr_t
ikrt_posix_getsockopt (ikptr_t s_sock, ikptr_t s_level, ikptr_t s_optname, ikptr_t s_optval)
{
#ifdef HAVE_GETSOCKOPT
  void *	optval = IK_BYTEVECTOR_DATA_VOIDP(s_optval);
  socklen_t	optlen = (socklen_t)IK_BYTEVECTOR_LENGTH(s_optval);
  int		rv;
  errno = 0;
  rv	= getsockopt(IK_NUM_TO_FD(s_sock), IK_UNFIX(s_level), IK_UNFIX(s_optname), optval, &optlen);
  return (0 == rv)? IK_FIX(0) : ik_errno_to_code();
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_setsockopt (ikptr_t s_sock, ikptr_t s_level, ikptr_t s_optname, ikptr_t s_optval)
{
#ifdef HAVE_SETSOCKOPT
  void *	optval = IK_BYTEVECTOR_DATA_VOIDP(s_optval);
  socklen_t	optlen = (socklen_t)IK_BYTEVECTOR_LENGTH(s_optval);
  int		rv;
  errno = 0;
  rv	= setsockopt(IK_NUM_TO_FD(s_sock), IK_UNFIX(s_level), IK_UNFIX(s_optname), optval, optlen);
  return (0 == rv)? IK_FIX(0) : ik_errno_to_code();
#else
  feature_failure(__func__);
#endif
}

/* ------------------------------------------------------------------ */

ikptr_t
ikrt_posix_setsockopt_int (ikptr_t s_sock, ikptr_t s_level, ikptr_t s_optname, ikptr_t s_optval_num)
{
#ifdef HAVE_SETSOCKOPT
  int		optval;
  socklen_t	optlen = sizeof(int);
  int		rv;
  if (IK_TRUE_OBJECT == s_optval_num)
    optval = 1;
  else if (IK_FALSE_OBJECT == s_optval_num)
    optval = 0;
  else {
    optval = ik_integer_to_int(s_optval_num);
  }
  errno = 0;
  rv	= setsockopt(IK_NUM_TO_FD(s_sock), IK_UNFIX(s_level), IK_UNFIX(s_optname), &optval, optlen);
  return (0 == rv)? IK_FIX(0) : ik_errno_to_code();
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_getsockopt_int (ikptr_t s_sock, ikptr_t s_level, ikptr_t s_optname, ikpcb_t * pcb)
{
#ifdef HAVE_GETSOCKOPT
  int		optval;
  socklen_t	optlen = sizeof(int);
  int		rv;
  errno = 0;
  rv	= getsockopt(IK_NUM_TO_FD(s_sock), IK_UNFIX(s_level), IK_UNFIX(s_optname), &optval, &optlen);
  if (0 == rv) {
    /* Return  a pair  to distinguish  the value  from an  encoded errno
       value. */
    ikptr_t	s_pair = ika_pair_alloc(pcb);
    pcb->root0 = &s_pair;
    {
      IK_ASS(IK_CAR(s_pair), ika_integer_from_int(pcb, optval));
      IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_CAR_PTR(s_pair));
      IK_CDR(s_pair) = IK_TRUE_OBJECT;
    }
    pcb->root0 = NULL;
    return s_pair;
  } else
    return ik_errno_to_code();
#else
  feature_failure(__func__);
#endif
}

/* ------------------------------------------------------------------ */

ikptr_t
ikrt_posix_setsockopt_size_t (ikptr_t s_sock, ikptr_t s_level, ikptr_t s_optname, ikptr_t s_optval_num)
{
#ifdef HAVE_SETSOCKOPT
  size_t	optval = ik_integer_to_size_t(s_optval_num);
  socklen_t	optlen = sizeof(size_t);
  int		rv;
  errno = 0;
  rv	= setsockopt(IK_NUM_TO_FD(s_sock), IK_UNFIX(s_level), IK_UNFIX(s_optname), &optval, optlen);
  return (0 == rv)? IK_FIX(0) : ik_errno_to_code();
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_getsockopt_size_t (ikptr_t s_sock, ikptr_t s_level, ikptr_t s_optname, ikpcb_t * pcb)
{
#ifdef HAVE_GETSOCKOPT
  size_t	optval;
  socklen_t	optlen = sizeof(size_t);
  int		rv;
  errno = 0;
  rv	= getsockopt(IK_NUM_TO_FD(s_sock), IK_UNFIX(s_level), IK_UNFIX(s_optname), &optval, &optlen);
  if (0 == rv) {
    /* Return  a pair  to distinguish  the value  from an  encoded errno
       value. */
    ikptr_t	s_pair = ika_pair_alloc(pcb);
    pcb->root0 = &s_pair;
    {
      IK_ASS(IK_CAR(s_pair), ika_integer_from_size_t(pcb, optval));
      IK_CDR(s_pair) = IK_TRUE_OBJECT;
      IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_CDR_PTR(s_pair));
    }
    pcb->root0 = NULL;
    return s_pair;
  } else
    return ik_errno_to_code();
#else
  feature_failure(__func__);
#endif
}

/* ------------------------------------------------------------------ */

ikptr_t
ikrt_posix_setsockopt_linger (ikptr_t s_sock, ikptr_t onoff, ikptr_t linger)
{
#ifdef HAVE_SETSOCKOPT
  struct linger optval;
  socklen_t	optlen = sizeof(struct linger);
  int		rv;
  optval.l_onoff  = IK_BOOLEAN_TO_INT(onoff);
  optval.l_linger = IK_UNFIX(linger);
  errno = 0;
  rv	= setsockopt(IK_NUM_TO_FD(s_sock), SOL_SOCKET, SO_LINGER, &optval, optlen);
  return (0 == rv)? IK_FIX(0) : ik_errno_to_code();
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_getsockopt_linger (ikptr_t s_sock, ikpcb_t * pcb)
{
#ifdef HAVE_GETSOCKOPT
  struct linger optval;
  socklen_t	optlen = sizeof(struct linger);
  int		rv;
  errno = 0;
  rv	= getsockopt(IK_NUM_TO_FD(s_sock), SOL_SOCKET, SO_LINGER, &optval, &optlen);
  if (0 == rv) {
    /* Return two values in a pair. */
    ikptr_t	s_pair = ika_pair_alloc(pcb);
    pcb->root0 = &s_pair;
    {
      IK_ASS(IK_CAR(s_pair), IK_BOOLEAN_FROM_INT(optval.l_onoff));
      IK_ASS(IK_CDR(s_pair), ika_integer_from_int(pcb, optval.l_linger));
      IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_CDR_PTR(s_pair));
    }
    pcb->root0 = NULL;
    return s_pair;
  } else
    return ik_errno_to_code();
#else
  feature_failure(__func__);
#endif
}


/** --------------------------------------------------------------------
 ** Users and groups.
 ** ----------------------------------------------------------------- */

ikptr_t
ikrt_posix_getuid (void)
{
#ifdef HAVE_GETUID
  return IK_UID_TO_NUM(getuid());
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_getgid (void)
{
#ifdef HAVE_GETGID
  return IK_GID_TO_NUM(getgid());
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_geteuid (void)
{
#ifdef HAVE_GETEUID
  return IK_UID_TO_NUM(geteuid());
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_getegid (void)
{
#ifdef HAVE_GETEGID
  return IK_GID_TO_NUM(getegid());
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_getgroups (ikpcb_t * pcb)
{
#ifdef HAVE_GETGROUPS
  int	count;
  errno = 0;
  count = getgroups(0, NULL);
  if (errno)
    return ik_errno_to_code();
  else {
    gid_t	gids[count];
    errno = 0;
    count = getgroups(count, gids);
    if (-1 == count)
      return ik_errno_to_code();
    else if (0 == count)
      return IK_NULL_OBJECT;
    else {
      ikptr_t	s_list_of_gids, s_spine;
      int	i;
      s_list_of_gids = s_spine = ika_pair_alloc(pcb);
      pcb->root0 = &s_list_of_gids;
      pcb->root1 = &s_spine;
      {
	for (i=0; i<count;) {
	  IK_CAR(s_spine) = IK_GID_TO_NUM(gids[i]);
	  IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_CAR_PTR(s_spine));
	  if (++i<count) {
	    IK_ASS(IK_CDR(s_spine), ika_pair_alloc(pcb));
	    IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_CDR_PTR(s_spine));
	    s_spine = IK_CDR(s_spine);
	  } else {
	    IK_CDR(s_spine) = IK_NULL_OBJECT;
	    break;
	  }
	}
      }
      pcb->root1 = NULL;
      pcb->root0 = NULL;
      return s_list_of_gids;
    }
  }
#else
  feature_failure(__func__);
#endif
}

/* ------------------------------------------------------------------ */

ikptr_t
ikrt_posix_seteuid (ikptr_t s_new_uid)
{
#ifdef HAVE_SETEUID
  int	rv;
  errno = 0;
  rv	= seteuid(IK_NUM_TO_UID(s_new_uid));
  return (0 == rv)? IK_FIX(0) : ik_errno_to_code();
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_setuid (ikptr_t s_new_uid)
{
#ifdef HAVE_SETUID
  int	rv;
  errno = 0;
  rv	= setuid(IK_NUM_TO_UID(s_new_uid));
  return (0 == rv)? IK_FIX(0) : ik_errno_to_code();
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_setreuid (ikptr_t s_real_uid, ikptr_t s_effective_uid)
{
#ifdef HAVE_SETREUID
  int	rv;
  errno = 0;
  rv	= setreuid(IK_NUM_TO_UID(s_real_uid), IK_NUM_TO_UID(s_effective_uid));
  return (0 == rv)? IK_FIX(0) : ik_errno_to_code();
#else
  feature_failure(__func__);
#endif
}

/* ------------------------------------------------------------------ */

ikptr_t
ikrt_posix_setegid (ikptr_t s_new_gid)
{
#ifdef HAVE_SETEGID
  int	rv;
  errno = 0;
  rv	= setegid(IK_NUM_TO_GID(s_new_gid));
  return (0 == rv)? IK_FIX(0) : ik_errno_to_code();
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_setgid (ikptr_t s_new_gid)
{
#ifdef HAVE_SETGID
  int	rv;
  errno = 0;
  rv	= setgid(IK_NUM_TO_GID(s_new_gid));
  return (0 == rv)? IK_FIX(0) : ik_errno_to_code();
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_setregid (ikptr_t s_real_gid, ikptr_t s_effective_gid)
{
#ifdef HAVE_SETREGID
  int	rv;
  errno = 0;
  rv	= setregid(IK_NUM_TO_GID(s_real_gid), IK_NUM_TO_GID(s_effective_gid));
  return (0 == rv)? IK_FIX(0) : ik_errno_to_code();
#else
  feature_failure(__func__);
#endif
}

/* ------------------------------------------------------------------ */

ikptr_t
ikrt_posix_getlogin (ikpcb_t * pcb)
{
#ifdef HAVE_GETLOGIN
  char *	username;
  username = getlogin();
  return (username)? ika_bytevector_from_cstring(pcb, username) : IK_FALSE_OBJECT;
#else
  feature_failure(__func__);
#endif
}


/** --------------------------------------------------------------------
 ** Passwords database.
 ** ----------------------------------------------------------------- */

#ifdef HAVE_STRUCT_PASSWD
static ikptr_t
passwd_to_struct (ikptr_t s_rtd, struct passwd * src, ikpcb_t * pcb)
/* Convert  a  C  language   "struct  passwd"  into  a  Scheme  language
   "struct-passwd".  Makes use of "pcb->root9". */
{
  ikptr_t s_dst = ika_struct_alloc_and_init(pcb, s_rtd); /* this uses "pcb->root9" */
  pcb->root9 = &s_dst;
  {
    IK_ASS(IK_FIELD(s_dst, 0), ika_bytevector_from_cstring(pcb, src->pw_name));
    IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_FIELD_PTR(s_dst, 0));

    IK_ASS(IK_FIELD(s_dst, 1), ika_bytevector_from_cstring(pcb, src->pw_passwd));
    IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_FIELD_PTR(s_dst, 1));

    IK_ASS(IK_FIELD(s_dst, 2), IK_FIX(src->pw_uid));
    IK_ASS(IK_FIELD(s_dst, 3), IK_FIX(src->pw_gid));

    IK_ASS(IK_FIELD(s_dst, 4), ika_bytevector_from_cstring(pcb, src->pw_gecos));
    IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_FIELD_PTR(s_dst, 4));

    IK_ASS(IK_FIELD(s_dst, 5), ika_bytevector_from_cstring(pcb, src->pw_dir));
    IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_FIELD_PTR(s_dst, 5));

    IK_ASS(IK_FIELD(s_dst, 6), ika_bytevector_from_cstring(pcb, src->pw_shell));
    IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_FIELD_PTR(s_dst, 6));
  }
  pcb->root9 = NULL;
  return s_dst;
}
#endif
ikptr_t
ikrt_posix_getpwuid (ikptr_t s_rtd, ikptr_t s_uid, ikpcb_t * pcb)
{
#ifdef HAVE_GETPWUID
  struct passwd *	entry;
  entry = getpwuid(IK_NUM_TO_UID(s_uid));
  return (entry)? passwd_to_struct(s_rtd, entry, pcb) : IK_FALSE_OBJECT;
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_getpwnam (ikptr_t s_rtd, ikptr_t s_name, ikpcb_t * pcb)
{
#ifdef HAVE_GETPWNAM
  char *		name;
  struct passwd *	entry;
  name	= IK_BYTEVECTOR_DATA_CHARP(s_name);
  entry = getpwnam(name);
  return (entry)? passwd_to_struct(s_rtd, entry, pcb) : IK_FALSE_OBJECT;
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_user_entries (ikptr_t s_rtd, ikpcb_t * pcb)
{
#if ((defined HAVE_SETPWENT) && (defined HAVE_GETPWENT) && (defined HAVE_ENDPWENT))
  struct passwd *	entry;
  ikptr_t			s_list_of_entries;
  setpwent();
  {
    entry = getpwent();
    if (entry) {
      ikptr_t	s_spine;
      pcb->root0 = &s_rtd;
      {
	s_list_of_entries = s_spine = ika_pair_alloc(pcb);
	pcb->root1 = &s_list_of_entries;
	pcb->root2 = &s_spine;
	{
	  while (entry) {
	    IK_ASS(IK_CAR(s_spine), passwd_to_struct(s_rtd, entry, pcb));
	    IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_CAR_PTR(s_spine));
	    entry = getpwent();
	    if (entry) {
	      IK_ASS(IK_CDR(s_spine), ika_pair_alloc(pcb));
	      IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_CDR_PTR(s_spine));
	      s_spine = IK_CDR(s_spine);
	    } else {
	      IK_CDR(s_spine) = IK_NULL_OBJECT;
	      break;
	    }
	  }
	}
	pcb->root2 = NULL;
	pcb->root1 = NULL;
      }
      pcb->root0 = NULL;
    } else
      s_list_of_entries = IK_NULL_OBJECT;
  }
  endpwent();
  return s_list_of_entries;
#else
  feature_failure(__func__);
#endif
}


/** --------------------------------------------------------------------
 ** Groups database.
 ** ----------------------------------------------------------------- */

#ifdef HAVE_STRUCT_GROUP
static ikptr_t
group_to_struct (ikptr_t s_rtd, struct group * src, ikpcb_t * pcb)
/* Convert  a   C  language  "struct  group"  into   a  Scheme  language
   "struct-group".  Makes use of "pcb->root7,8,9". */
{
  ikptr_t s_dst = ika_struct_alloc_and_init(pcb, s_rtd); /* this uses "pcb->root9" */
  pcb->root9 = &s_dst;
  {
    IK_ASS(IK_FIELD(s_dst, 0), ika_bytevector_from_cstring(pcb, src->gr_name));
    IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_FIELD_PTR(s_dst, 0));
    IK_FIELD(s_dst, 1) = IK_FIX(src->gr_gid);
    {
      ikptr_t	s_list_of_users;
      if (src->gr_mem[0]) {
	ikptr_t	s_spine;
	int	i;
	s_list_of_users = s_spine = ika_pair_alloc(pcb);
	pcb->root8 = &s_list_of_users;
	pcb->root7 = &s_spine;
	{
	  for (i=0; src->gr_mem[i];) {
	    IK_ASS(IK_CAR(s_spine), ika_bytevector_from_cstring(pcb, src->gr_mem[i]));
	    IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_CAR_PTR(s_spine));
	    if (src->gr_mem[++i]) {
	      IK_ASS(IK_CDR(s_spine), ika_pair_alloc(pcb));
	      IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_CDR_PTR(s_spine));
	      s_spine = IK_CDR(s_spine);
	    } else {
	      IK_CDR(s_spine) = IK_NULL_OBJECT;
	      break;
	    }
	  }
	}
	pcb->root7 = NULL;
	pcb->root8 = NULL;
      } else
	s_list_of_users = IK_NULL_OBJECT;
      IK_FIELD(s_dst, 2) = s_list_of_users;
      IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_FIELD_PTR(s_dst, 2));
    }
  }
  pcb->root9 = NULL;
  return s_dst;
}
#endif
ikptr_t
ikrt_posix_getgrgid (ikptr_t s_rtd, ikptr_t s_gid, ikpcb_t * pcb)
{
#ifdef HAVE_GETGRGID
  struct group *       entry;
  entry = getgrgid(IK_NUM_TO_GID(s_gid));
  return (entry)? group_to_struct(s_rtd, entry, pcb) : IK_FALSE_OBJECT;
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_getgrnam (ikptr_t s_rtd, ikptr_t s_name, ikpcb_t * pcb)
{
#ifdef HAVE_GETGRNAM
  char *		name;
  struct group *       entry;
  name	= IK_BYTEVECTOR_DATA_CHARP(s_name);
  entry = getgrnam(name);
  return (entry)? group_to_struct(s_rtd, entry, pcb) : IK_FALSE_OBJECT;
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_group_entries (ikptr_t s_rtd, ikpcb_t * pcb)
{
#if ((defined HAVE_SETGRENT) && (defined HAVE_GETGRENT) && (defined HAVE_ENDGRENT))
  struct group *	entry;
  ikptr_t			s_list_of_entries;
  setgrent();
  {
    entry = getgrent();
    if (entry) {
      pcb->root0 = &s_rtd;
      {
	ikptr_t	s_spine = s_list_of_entries = ika_pair_alloc(pcb);
	pcb->root1 = &s_list_of_entries;
	pcb->root2 = &s_spine;
	{
	  while (entry) {
	    IK_ASS(IK_CAR(s_spine), group_to_struct(s_rtd, entry, pcb));
	    IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_CAR_PTR(s_spine));
	    entry = getgrent();
	    if (entry) {
	      IK_ASS(IK_CDR(s_spine), ika_pair_alloc(pcb));
	      IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_CDR_PTR(s_spine));
	      s_spine = IK_CDR(s_spine);
	    } else {
	      IK_CDR(s_spine) = IK_NULL_OBJECT;
	      break;
	    }
	  }
	}
	pcb->root2 = NULL;
	pcb->root1 = NULL;
      }
      pcb->root0 = NULL;
    } else
      s_list_of_entries = IK_NULL_OBJECT;
  }
  endgrent();
  return s_list_of_entries;
#else
  feature_failure(__func__);
#endif
}


/** --------------------------------------------------------------------
 ** Job control.
 ** ----------------------------------------------------------------- */

ikptr_t
ikrt_posix_ctermid (ikpcb_t * pcb)
{
#ifdef HAVE_CTERMID
  char		id[L_ctermid];
  ctermid(id);
  return ika_bytevector_from_cstring(pcb, id);
#else
  feature_failure(__func__);
#endif
}

/* ------------------------------------------------------------------ */

ikptr_t
ikrt_posix_setsid (void)
{
#ifdef HAVE_SETSID
  int	rv;
  errno = 0;
  rv	= setsid();
  return (-1 != rv)? IK_PID_TO_NUM(rv) : ik_errno_to_code();
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_getsid (ikptr_t s_pid)
{
#ifdef HAVE_GETSID
  int	rv;
  errno = 0;
  rv	= getsid(IK_NUM_TO_PID(s_pid));
  return (-1 != rv)? IK_PID_TO_NUM(rv) : ik_errno_to_code();
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_getpgrp (void)
/* About  this	 function:  notice  that  we   define  "_GNU_SOURCE"  in
   "configure.ac".  See the GNU C Library documentation for details. */
{
#ifdef HAVE_GETPGRP
  return IK_PID_TO_NUM(getpgrp());
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_setpgid (ikptr_t s_pid, ikptr_t s_pgid)
{
#ifdef HAVE_SETPGID
  int	rv;
  errno = 0;
  rv	= setpgid(IK_NUM_TO_PID(s_pid), IK_NUM_TO_PID(s_pgid));
  return (-1 != rv)? IK_FIX(0) : ik_errno_to_code();
#else
  feature_failure(__func__);
#endif
}

/* ------------------------------------------------------------------ */

ikptr_t
ikrt_posix_tcgetpgrp (ikptr_t s_fd)
{
#ifdef HAVE_TCGETPGRP
  pid_t	rv;
  errno = 0;
  rv	= tcgetpgrp(IK_NUM_TO_FD(s_fd));
  return (-1 != rv)? IK_PID_TO_NUM(rv) : ik_errno_to_code();
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_tcsetpgrp (ikptr_t s_fd, ikptr_t s_pgid)
{
#ifdef HAVE_TCSETPGRP
  int	rv;
  errno = 0;
  rv	= tcsetpgrp(IK_NUM_TO_PID(s_fd), IK_NUM_TO_PID(s_pgid));
  return (0 == rv)? IK_FIX(0) : ik_errno_to_code();
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_tcgetsid (ikptr_t s_fd)
{
#ifdef HAVE_TCGETSID
  pid_t	rv;
  errno = 0;
  rv	= tcgetsid(IK_NUM_TO_FD(s_fd));
  return (-1 != rv)? IK_PID_TO_NUM(rv) : ik_errno_to_code();
#else
  feature_failure(__func__);
#endif
}


/** --------------------------------------------------------------------
 ** Date and time related functions.
 ** ----------------------------------------------------------------- */

ikptr_t
ikrt_posix_clock (ikpcb_t * pcb)
{
#ifdef HAVE_CLOCK
  clock_t	T;
  T = clock();
  return (((clock_t)-1) != T)? ika_flonum_from_double(pcb, (double)T) : IK_FALSE_OBJECT;
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_time (ikpcb_t * pcb)
{
#ifdef HAVE_TIME
  time_t	T;
  T = time(NULL);
  return (((time_t)-1) != T)? ika_flonum_from_double(pcb, (double)T) : IK_FALSE_OBJECT;
#else
  feature_failure(__func__);
#endif
}

/* ------------------------------------------------------------------ */

#ifdef HAVE_STRUCT_TMS
static ikptr_t
tms_to_struct (ikptr_t s_rtd, struct tms * src, ikpcb_t * pcb)
/* Convert   a  C  language   "struct  tms"   into  a   Scheme  language
   "struct-tms".  Makes use of "pcb->root9". */
{
  ikptr_t s_dst = ika_struct_alloc_and_init(pcb, s_rtd); /* this uses "pcb->root9" */
  pcb->root9 = &s_dst;
  {
#if 0
    fprintf(stderr, "struct tms = %f, %f, %f, %f\n",
	    (double)(src->tms_utime),  (double)(src->tms_stime),
	    (double)(src->tms_cutime), (double)(src->tms_cstime));
#endif
    IK_ASS(IK_FIELD(s_dst, 0), ika_flonum_from_double(pcb, (double)(src->tms_utime)));
    IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_FIELD_PTR(s_dst, 0));

    IK_ASS(IK_FIELD(s_dst, 1), ika_flonum_from_double(pcb, (double)(src->tms_stime)));
    IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_FIELD_PTR(s_dst, 1));

    IK_ASS(IK_FIELD(s_dst, 2), ika_flonum_from_double(pcb, (double)(src->tms_cutime)));
    IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_FIELD_PTR(s_dst, 2));

    IK_ASS(IK_FIELD(s_dst, 3), ika_flonum_from_double(pcb, (double)(src->tms_cstime)));
    IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_FIELD_PTR(s_dst, 3));
  }
  pcb->root9 = NULL;
  return s_dst;
}
#endif
ikptr_t
ikrt_posix_times (ikptr_t s_rtd, ikpcb_t * pcb)
{
#ifdef HAVE_TIMES
  struct tms	T = { 0, 0, 0, 0 };
  clock_t	rv;
  rv = times(&T);
  return (((clock_t)-1) == rv)? IK_FALSE_OBJECT : tms_to_struct(s_rtd, &T, pcb);
#else
  feature_failure(__func__);
#endif
}

/* ------------------------------------------------------------------ */

ikptr_t
ikrt_posix_gettimeofday (ikptr_t s_rtd, ikpcb_t * pcb)
{
#ifdef HAVE_GETTIMEOFDAY
  struct timeval	T;
  int			rv;
  errno = 0;
  rv	= gettimeofday(&T, NULL);
  if (0 == rv) {
    ikptr_t	s_stru = ika_struct_alloc_and_init(pcb, s_rtd);
    pcb->root0 = &s_stru;
    {
      IK_ASS(IK_FIELD(s_stru, 0), ika_integer_from_long(pcb, T.tv_sec));
      IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_FIELD_PTR(s_stru, 0));

      IK_ASS(IK_FIELD(s_stru, 1), ika_integer_from_long(pcb, T.tv_usec));
      IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_FIELD_PTR(s_stru, 1));
    }
    pcb->root0 = NULL;
    return s_stru;
  } else
    return ik_errno_to_code();
#else
  feature_failure(__func__);
#endif
}

/* ------------------------------------------------------------------ */

#ifdef HAVE_STRUCT_TM
static ikptr_t
tm_to_struct (ikptr_t s_rtd, struct tm * src, ikpcb_t * pcb)
/* Convert a C language "struct  tm" into a Scheme language "struct-tm".
   Makes use of "pcb->root9" only. */
{
  ikptr_t s_dst = ika_struct_alloc_and_init(pcb, s_rtd); /* this uses "pcb->root9" */
  pcb->root9 = &s_dst;
  {
    IK_ASS(IK_FIELD(s_dst, 0), ika_integer_from_long(pcb, (long)(src->tm_sec)));
    IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_FIELD_PTR(s_dst, 0));

    IK_ASS(IK_FIELD(s_dst, 1), ika_integer_from_long(pcb, (long)(src->tm_min)));
    IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_FIELD_PTR(s_dst, 1));

    IK_ASS(IK_FIELD(s_dst, 2), ika_integer_from_long(pcb, (long)(src->tm_hour)));
    IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_FIELD_PTR(s_dst, 2));

    IK_ASS(IK_FIELD(s_dst, 3), ika_integer_from_long(pcb, (long)(src->tm_mday)));
    IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_FIELD_PTR(s_dst, 3));

    IK_ASS(IK_FIELD(s_dst, 4), ika_integer_from_long(pcb, (long)(src->tm_mon)));
    IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_FIELD_PTR(s_dst, 4));

    IK_ASS(IK_FIELD(s_dst, 5), ika_integer_from_long(pcb, (long)(src->tm_year)));
    IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_FIELD_PTR(s_dst, 5));

    IK_ASS(IK_FIELD(s_dst, 6), ika_integer_from_long(pcb, (long)(src->tm_wday)));
    IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_FIELD_PTR(s_dst, 6));

    IK_ASS(IK_FIELD(s_dst, 7), ika_integer_from_long(pcb, (long)(src->tm_yday)));
    IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_FIELD_PTR(s_dst, 7));

    IK_FIELD(s_dst, 8) = (src->tm_isdst)? IK_TRUE_OBJECT : IK_FALSE_OBJECT;

#ifdef HAVE_TM_TM_GMTOFF
    IK_ASS(IK_FIELD(s_dst, 9), ika_integer_from_long(pcb, src->tm_gmtoff));
    IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_FIELD_PTR(s_dst, 9));
#else
    IK_ASS(IK_FIELD(s_dst, 9), IK_FALSE);
#endif

#ifdef HAVE_TM_TM_ZONE
    IK_ASS(IK_FIELD(s_dst,10), ika_bytevector_from_cstring(pcb, src->tm_zone));
    IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_FIELD_PTR(s_dst, 10));
#else
    IK_ASS(IK_FIELD(s_dst,10), IK_FALSE);
#endif
  }
  pcb->root9 = NULL;
  return s_dst;
}
#endif
ikptr_t
ikrt_posix_localtime (ikptr_t s_rtd, ikptr_t s_time_num, ikpcb_t * pcb)
{
#ifdef HAVE_LOCALTIME_R
  time_t	time = (time_t)ik_integer_to_ulong(s_time_num);
  struct tm	T;
  struct tm *	rv;
  rv	= localtime_r(&time, &T);
  return (rv)? tm_to_struct(s_rtd, &T, pcb) : IK_FALSE_OBJECT;
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_gmtime (ikptr_t s_rtd, ikptr_t s_time_num, ikpcb_t * pcb)
{
#ifdef HAVE_GMTIME_R
  time_t	time = (time_t)ik_integer_to_ulong(s_time_num);
  struct tm	T;
  struct tm *	rv;
  errno = 0;
  rv	= gmtime_r(&time, &T);
  return (rv)? tm_to_struct(s_rtd, &T, pcb) : IK_FALSE_OBJECT;
#else
  feature_failure(__func__);
#endif
}

/* ------------------------------------------------------------------ */

#ifdef HAVE_STRUCT_TM
static void
struct_to_tm (ikptr_t s_src, struct tm * dst)
/* Convert  a Scheme  language	"struct-tm" into  a  C language	 "struct
   tm". */
{
  dst->tm_sec	= ik_integer_to_long(IK_FIELD(s_src, 0));
  dst->tm_min	= ik_integer_to_long(IK_FIELD(s_src, 1));
  dst->tm_hour	= ik_integer_to_long(IK_FIELD(s_src, 2));
  dst->tm_mday	= ik_integer_to_long(IK_FIELD(s_src, 3));
  dst->tm_mon	= ik_integer_to_long(IK_FIELD(s_src, 4));
  dst->tm_year	= ik_integer_to_long(IK_FIELD(s_src, 5));
  dst->tm_wday	= ik_integer_to_long(IK_FIELD(s_src, 6));
  dst->tm_yday	= ik_integer_to_long(IK_FIELD(s_src, 7));
  dst->tm_isdst = (IK_TRUE_OBJECT == IK_FIELD(s_src, 8))? 1 : 0;
#ifdef HAVE_TM_TM_GMTOFF
  dst->tm_gmtoff= ik_integer_to_long(IK_FIELD(s_src, 9));
#endif
#ifdef HAVE_TM_TM_ZONE
  dst->tm_zone	= IK_BYTEVECTOR_DATA_CHARP(IK_FIELD(s_src, 10));
#endif
}
#endif
ikptr_t
ikrt_posix_timelocal (ikptr_t s_tm_struct, ikpcb_t * pcb)
{
#ifdef HAVE_TIMELOCAL
  struct tm	T;
  time_t	rv;
  struct_to_tm(s_tm_struct, &T);
  rv = timelocal(&T);
  return (((time_t)-1) != rv)? ika_flonum_from_double(pcb, (double)rv) : IK_FALSE_OBJECT;
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_timegm (ikptr_t s_tm_struct, ikpcb_t * pcb)
{
#ifdef HAVE_TIMEGM
  struct tm	T;
  time_t	rv;
  struct_to_tm(s_tm_struct, &T);
  rv = timegm(&T);
  return (((time_t)-1) != rv)? ika_flonum_from_double(pcb, (double)rv) : IK_FALSE_OBJECT;
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_strftime (ikptr_t s_template, ikptr_t s_tm_struct, ikpcb_t *pcb)
{
#ifdef HAVE_STRFTIME
  struct tm	T;
  const char *	template;
#undef SIZE
#define SIZE	IK_CHUNK_SIZE
  size_t	size=SIZE;
  char		output[SIZE+1];
  template = IK_BYTEVECTOR_DATA_CHARP(s_template);
  struct_to_tm(s_tm_struct, &T);
  output[0] = '\1';
  size = strftime(output, size, template, &T);
  return (0 == size && '\0' != output[0])?
    IK_FALSE_OBJECT : ika_bytevector_from_cstring_len(pcb, output, size);
#else
  feature_failure(__func__);
#endif
}

/* ------------------------------------------------------------------ */

ikptr_t
ikrt_posix_nanosleep (ikptr_t s_secs, ikptr_t s_nsecs, ikpcb_t * pcb)
{
#ifdef HAVE_NANOSLEEP
  struct timespec	requested;
  struct timespec	remaining = { 0, 0 }; /* required!!! */
  int			rv;
  requested.tv_sec  = IK_IS_FIXNUM(s_secs)?  (long)IK_UNFIX(s_secs) :IK_REF(s_secs, off_bignum_data);
  requested.tv_nsec = IK_IS_FIXNUM(s_nsecs)? (long)IK_UNFIX(s_nsecs):IK_REF(s_nsecs,off_bignum_data);
  errno = 0;
  rv	= nanosleep(&requested, &remaining);
  if (0 == rv) {
    ikptr_t	s_pair = ika_pair_alloc(pcb);
    pcb->root0 = &s_pair;
    {
      IK_ASS(IK_CAR(s_pair), remaining.tv_sec?  ika_integer_from_long(pcb, remaining.tv_sec)  : IK_FALSE_OBJECT);
      IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_CAR_PTR(s_pair));

      IK_ASS(IK_CDR(s_pair), remaining.tv_nsec? ika_integer_from_long(pcb, remaining.tv_nsec) : IK_FALSE_OBJECT);
      IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_CDR_PTR(s_pair));
    }
    pcb->root0 = NULL;
    return s_pair;
  } else
    return ik_errno_to_code();
#else
  feature_failure(__func__);
#endif
}

/* ------------------------------------------------------------------ */

ikptr_t
ikrt_current_time (ikptr_t t)
{
#ifdef HAVE_GETTIMEOFDAY
  struct timeval s;
  gettimeofday(&s, 0);
  /* this will break in 8,727,224 years if we stay in 32-bit ptrs */
  IK_FIELD(t, 0) = IK_FIX(s.tv_sec / 1000000);
  IK_FIELD(t, 1) = IK_FIX(s.tv_sec % 1000000);
  IK_FIELD(t, 2) = IK_FIX(s.tv_usec);
  return t;
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_gmt_offset (ikptr_t t)
{
#if ((defined HAVE_GMTIME_R) && (defined HAVE_MKTIME))
  time_t	clock;
  struct tm	m;
  time_t	gmtclock;
  clock	   = IK_UNFIX(IK_FIELD(t, 0)) * 1000000 + IK_UNFIX(IK_FIELD(t, 1));
  gmtime_r(&clock, &m);
  gmtclock = mktime(&m);
  return IK_FIX(clock - gmtclock);
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_bvftime (ikptr_t outbv, ikptr_t fmtbv)
{
#if ((defined HAVE_TIME) && (defined HAVE_LOCALTIME_R) && (defined HAVE_STRFTIME))
  time_t	t;
  struct tm	tmp;
  int		rv;
  t     = time(NULL);
  errno = 0;
  localtime_r(&t, &tmp);
  errno = 0;
  rv    = strftime((char*)(ikuword_t)(outbv + off_bytevector_data),
		   IK_UNFIX(IK_REF(outbv, off_bytevector_length)) + 1,
		   (char*)(ikuword_t)(fmtbv + off_bytevector_data),
		   &tmp);
#ifdef VICARE_DEBUGGING
  if (rv == 0)
    ik_debug_message("error in strftime: %s\n", strerror(errno));
#endif
  return IK_FIX(rv);
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_current_time_fixnums (ikpcb_t * pcb)
{
#if ((defined HAVE_TIME) && (defined HAVE_GMTIME_R))
  time_t	T;
  struct tm	D;
  ikptr_t		s_vec;
  T     = time(NULL);
  errno = 0;
  localtime_r(&T, &D);
  errno = 0;
  s_vec = ika_vector_alloc_and_init(pcb, 3);
  IK_ITEM(s_vec, 0) = IK_FIX(D.tm_year + 1900);
  IK_ITEM(s_vec, 1) = IK_FIX(D.tm_mon  + 1);
  IK_ITEM(s_vec, 2) = IK_FIX(D.tm_mday);
  return s_vec;
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_current_time_fixnums_2 (ikpcb_t * pcb)
{
#if ((defined HAVE_TIME) && (defined HAVE_GMTIME_R))
  time_t	T;
  struct tm	D;
  ikptr_t		s_vec;
  T     = time(NULL);
  errno = 0;
  localtime_r(&T, &D);
  errno = 0;
  s_vec = ika_vector_alloc_and_init(pcb, 6);
  IK_ITEM(s_vec, 0) = IK_FIX(D.tm_year + 1900);
  IK_ITEM(s_vec, 1) = IK_FIX(D.tm_mon  + 1);
  IK_ITEM(s_vec, 2) = IK_FIX(D.tm_mday);
  IK_ITEM(s_vec, 3) = IK_FIX(D.tm_hour);
  IK_ITEM(s_vec, 4) = IK_FIX(D.tm_min);
  IK_ITEM(s_vec, 5) = IK_FIX(D.tm_sec);
  return s_vec;
#else
  feature_failure(__func__);
#endif
}

/* ------------------------------------------------------------------ */

ikptr_t
ikrt_posix_setitimer (ikptr_t s_which, ikptr_t s_new)
{
#ifdef HAVE_SETITIMER
  ikptr_t			s_it_interval = IK_FIELD(s_new, 0);
  ikptr_t			s_it_value    = IK_FIELD(s_new, 1);
  struct itimerval	new;
  int			rv;
  new.it_interval.tv_sec  = ik_integer_to_long(IK_FIELD(s_it_interval, 0));
  new.it_interval.tv_usec = ik_integer_to_long(IK_FIELD(s_it_interval, 1));
  new.it_value.tv_sec     = ik_integer_to_long(IK_FIELD(s_it_value,    0));
  new.it_value.tv_usec    = ik_integer_to_long(IK_FIELD(s_it_value,    1));
  errno = 0;
  rv    = setitimer(IK_UNFIX(s_which), &new, NULL);
  return (0 == rv)? IK_FIX(0) : ik_errno_to_code();
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_getitimer (ikptr_t s_which, ikptr_t s_old, ikpcb_t * pcb)
{
#ifdef HAVE_GETITIMER
  struct itimerval	old;
  int			rv;
  errno = 0;
  rv    = getitimer(IK_UNFIX(s_which), &old);
  if (0 == rv) {
    pcb->root0 = &s_old;
    {
      IK_ASS(IK_FIELD(IK_FIELD(s_old, 0), 0), ika_integer_from_long(pcb, old.it_interval.tv_sec));
      IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_FIELD_PTR(IK_FIELD(s_old, 0), 0));

      IK_ASS(IK_FIELD(IK_FIELD(s_old, 0), 1), ika_integer_from_long(pcb, old.it_interval.tv_usec));
      IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_FIELD_PTR(IK_FIELD(s_old, 0), 1));

      IK_ASS(IK_FIELD(IK_FIELD(s_old, 1), 0), ika_integer_from_long(pcb, old.it_value.tv_sec));
      IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_FIELD_PTR(IK_FIELD(s_old, 1), 0));

      IK_ASS(IK_FIELD(IK_FIELD(s_old, 1), 1), ika_integer_from_long(pcb, old.it_value.tv_usec));
      IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_FIELD_PTR(IK_FIELD(s_old, 1), 1));
    }
    pcb->root0 = NULL;
    return IK_FIX(0);
  } else
    return ik_errno_to_code();
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_alarm (ikptr_t s_seconds, ikpcb_t * pcb)
{
#ifdef HAVE_ALARM
  unsigned	rv;
  rv    = alarm(ik_integer_to_uint(s_seconds));
  return ika_integer_from_uint(pcb, rv);
#else
  feature_failure(__func__);
#endif
}


/** --------------------------------------------------------------------
 ** Block/unblock interprocess signals.
 ** ----------------------------------------------------------------- */

ik_decl ikptr_t ikrt_posix_signal_bub_init	(void);
ik_decl ikptr_t ikrt_posix_signal_bub_final	(void);
ik_decl ikptr_t ikrt_posix_signal_bub_acquire	(void);
ik_decl ikptr_t ikrt_posix_signal_bub_delivered	(ikptr_t s_signum);

#if ((defined HAVE_SIGFILLSET) && (defined HAVE_SIGPROCMASK) && (defined HAVE_SIGACTION))
static int	arrived_signals[NSIG];
static sigset_t	all_signals_set;
static void
signal_bub_handler (int signum)
{
  ++(arrived_signals[signum]);
}
#endif
ikptr_t
ikrt_posix_signal_bub_init (void)
{ /* Block all the signals and register our handler for each. */
#if ((defined HAVE_SIGFILLSET) && (defined HAVE_SIGPROCMASK) && (defined HAVE_SIGACTION))
  struct sigaction	ac = {
    .sa_handler	= signal_bub_handler,
    .sa_flags	= SA_RESTART | SA_NOCLDSTOP
  };
  int	signum;
  sigfillset(&all_signals_set);
  sigprocmask(SIG_BLOCK, &all_signals_set, NULL);
  for (signum=0; signum<NSIG; ++signum) {
    arrived_signals[signum] = 0;
    sigaction(signum, &ac, NULL);
  }
  return IK_VOID_OBJECT;
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_signal_bub_final (void)
{ /* Set all the handlers to SIG_IGN, then unblock the signals. */
#if ((defined HAVE_SIGFILLSET) && (defined HAVE_SIGPROCMASK) && (defined HAVE_SIGACTION))
  struct sigaction	ac = {
    .sa_handler	= SIG_IGN,
    .sa_flags	= SA_RESTART
  };
  int	signum;
  for (signum=0; signum<NSIG; ++signum) {
    arrived_signals[signum] = 0;
    sigaction(signum, &ac, NULL);
  }
  sigprocmask(SIG_UNBLOCK, &all_signals_set, NULL);
  return IK_VOID_OBJECT;
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_signal_bub_acquire (void)
{ /* Unblock then block all the signals.  This causes blocked signals to
     be delivered. */
#if ((defined HAVE_SIGFILLSET) && (defined HAVE_SIGPROCMASK) && (defined HAVE_SIGACTION))
  sigprocmask(SIG_UNBLOCK, &all_signals_set, NULL);
  sigprocmask(SIG_BLOCK,   &all_signals_set, NULL);
  return IK_VOID_OBJECT;
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_signal_bub_delivered (ikptr_t s_signum)
{ /* Return true if  the signal SIGNUM has been  delivered at least once
     since  the last  call to  "ikrt_posix_signal_bub_acquire()".  Clear
     the signal flag. */
#if ((defined HAVE_SIGFILLSET) && (defined HAVE_SIGPROCMASK) && (defined HAVE_SIGACTION))
  int	signum = IK_UNFIX(s_signum);
  int	is_set = arrived_signals[signum];
  arrived_signals[signum] = 0;
  return is_set? IK_TRUE_OBJECT : IK_FALSE_OBJECT;
#else
  feature_failure(__func__);
#endif
}


/** --------------------------------------------------------------------
 ** Waiting for signals.
 ** ----------------------------------------------------------------- */

#if ((defined HAVE_SIGEMPTYSET) && (defined HAVE_SIGADDSET) \
     && ((defined HAVE_SIGWAITINFO) || (defined HAVE_SIGTIMEDWAIT)))
static void
posix_siginfo_to_struct (siginfo_t * info, ikptr_t s_struct, ikpcb_t * pcb)
{
  pcb->root9 = &s_struct;
  {
#ifdef HAVE_SIGINFO_SI_SIGNO
    IK_ASS(IK_FIELD(s_struct, 0), ika_integer_from_int(pcb, info->si_signo));
    IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_FIELD_PTR(s_struct, 0));
#else
    IK_ASS(IK_FIELD(s_struct, 0), IK_FALSE_OBJECT);
#endif

#ifdef HAVE_SIGINFO_SI_ERRNO
    IK_ASS(IK_FIELD(s_struct, 1), ika_integer_from_int(pcb, info->si_errno));
    IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_FIELD_PTR(s_struct, 1));
#else
    IK_ASS(IK_FIELD(s_struct, 1), IK_FALSE_OBJECT);
#endif

#ifdef HAVE_SIGINFO_SI_CODE
    IK_ASS(IK_FIELD(s_struct, 2), ika_integer_from_int(pcb, info->si_code));
    IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_FIELD_PTR(s_struct, 2));
#else
    IK_ASS(IK_FIELD(s_struct, 2), IK_FALSE_OBJECT);
#endif

#ifdef HAVE_SIGINFO_SI_TRAPNO
    IK_ASS(IK_FIELD(s_struct, 3), ika_integer_from_int(pcb, info->si_trapno));
    IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_FIELD_PTR(s_struct, 3));
#else
    IK_ASS(IK_FIELD(s_struct, 3), IK_FALSE_OBJECT);
#endif

#ifdef HAVE_SIGINFO_SI_PID
    IK_ASS(IK_FIELD(s_struct, 4), ika_integer_from_int(pcb, info->si_pid));
    IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_FIELD_PTR(s_struct, 4));
#else
    IK_ASS(IK_FIELD(s_struct, 4), IK_FALSE_OBJECT);
#endif

#ifdef HAVE_SIGINFO_SI_UID
    IK_ASS(IK_FIELD(s_struct, 5), ika_integer_from_int(pcb, info->si_uid));
    IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_FIELD_PTR(s_struct, 5));
#else
    IK_ASS(IK_FIELD(s_struct, 5), IK_FALSE_OBJECT);
#endif

#ifdef HAVE_SIGINFO_SI_STATUS
    IK_ASS(IK_FIELD(s_struct, 6), ika_integer_from_int(pcb, info->si_status));
    IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_FIELD_PTR(s_struct, 6));
#else
    IK_ASS(IK_FIELD(s_struct, 6), IK_FALSE_OBJECT);
#endif

#ifdef HAVE_SIGINFO_SI_UTIME
    IK_ASS(IK_FIELD(s_struct, 7), ika_integer_from_llong(pcb, (ik_llong)(info->si_utime)));
    IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_FIELD_PTR(s_struct, 7));
#else
    IK_ASS(IK_FIELD(s_struct, 7), IK_FALSE_OBJECT);
#endif

#ifdef HAVE_SIGINFO_SI_STIME
    IK_ASS(IK_FIELD(s_struct, 8), ika_integer_from_llong(pcb, (long long)(info->si_stime)));
    IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_FIELD_PTR(s_struct, 8));
#else
    IK_ASS(IK_FIELD(s_struct, 8), IK_FALSE_OBJECT);
#endif

#ifdef HAVE_SIGINFO_SI_VALUE
    IK_ASS(IK_FIELD(s_struct, 9), ika_integer_from_int(pcb, info->si_value.sival_int));
    IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_FIELD_PTR(s_struct, 9));
#else
    IK_ASS(IK_FIELD(s_struct, 9), IK_FALSE_OBJECT);
#endif

#ifdef HAVE_SIGINFO_SI_VALUE
    IK_ASS(IK_FIELD(s_struct, 10), ika_pointer_alloc(pcb, (ikuword_t)(info->si_value.sival_ptr)));
    IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_FIELD_PTR(s_struct, 10));
#else
    IK_ASS(IK_FIELD(s_struct, 10), IK_FALSE_OBJECT);
#endif

#ifdef HAVE_SIGINFO_SI_INT
    IK_ASS(IK_FIELD(s_struct, 11), ika_integer_from_int(pcb, info->si_int));
    IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_FIELD_PTR(s_struct, 11));
#else
    IK_ASS(IK_FIELD(s_struct, 11), IK_FALSE_OBJECT);
#endif

#ifdef HAVE_SIGINFO_SI_PTR
    IK_ASS(IK_FIELD(s_struct, 12), ika_pointer_alloc(pcb, (ikuword_t)(info->si_ptr)));
    IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_FIELD_PTR(s_struct, 12));
#else
    IK_ASS(IK_FIELD(s_struct, 12), IK_FALSE_OBJECT);
#endif

#ifdef HAVE_SIGINFO_SI_OVERRUN
    IK_ASS(IK_FIELD(s_struct, 13), ika_integer_from_int(pcb, info->si_overrun));
    IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_FIELD_PTR(s_struct, 13));
#else
    IK_ASS(IK_FIELD(s_struct, 13), IK_FALSE_OBJECT);
#endif

#ifdef HAVE_SIGINFO_SI_TIMERID
    IK_ASS(IK_FIELD(s_struct, 14), ika_integer_from_int(pcb, info->si_timerid));
    IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_FIELD_PTR(s_struct, 14));
#else
    IK_ASS(IK_FIELD(s_struct, 14), IK_FALSE_OBJECT);
#endif

#ifdef HAVE_SIGINFO_SI_ADDR
    IK_ASS(IK_FIELD(s_struct, 15), ika_pointer_alloc(pcb, (ikuword_t)(info->si_addr)));
    IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_FIELD_PTR(s_struct, 15));
#else
    IK_ASS(IK_FIELD(s_struct, 15), IK_FALSE_OBJECT);
#endif

#ifdef HAVE_SIGINFO_SI_BAND
    IK_ASS(IK_FIELD(s_struct, 16), ika_integer_from_long(pcb, info->si_band));
    IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_FIELD_PTR(s_struct, 16));
#else
    IK_ASS(IK_FIELD(s_struct, 16), IK_FALSE_OBJECT);
#endif

#ifdef HAVE_SIGINFO_SI_FD
    IK_ASS(IK_FIELD(s_struct, 17), ika_integer_from_int(pcb, info->si_fd));
    IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_FIELD_PTR(s_struct, 17));
#else
    IK_ASS(IK_FIELD(s_struct, 17), IK_FALSE_OBJECT);
#endif

#ifdef HAVE_SIGINFO_SI_ADDR_LSB
    IK_ASS(IK_FIELD(s_struct, 18), ika_integer_from_int(pcb, (int)info->si_addr_lsb));
    IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_FIELD_PTR(s_struct, 18));
#else
    IK_ASS(IK_FIELD(s_struct, 18), IK_FALSE_OBJECT);
#endif
  }
  pcb->root9 = NULL;
}
#endif

/* ------------------------------------------------------------------ */

ikptr_t
ikrt_posix_sigwaitinfo (ikptr_t s_signo, ikptr_t s_siginfo, ikpcb_t * pcb)
/* Interface to the C  function "sigwaitinfo()".  Synchronously wait for
   a queued signal; if successful  return a fixnum representing a signal
   number, else return an encoded "errno" value.

   S_SIGNO must be a fixnum representing an interprocess signal code.

   S_SIGINFO must be an instance  of "struct-siginfo_t", which is filled
   with the informations attached to the signal. */
{
#if ((defined HAVE_SIGEMPTYSET) && (defined HAVE_SIGADDSET) && (defined HAVE_SIGWAITINFO))
  sigset_t	set;
  siginfo_t	info;
  int		rv;
  sigemptyset(&set);
  rv = sigaddset(&set, IK_NUM_TO_SIGNUM(s_signo));
  if (-1 == rv)
    return ik_errno_to_code();
  rv = sigwaitinfo(&set, &info);
  if (0 < rv) {
    posix_siginfo_to_struct(&info, s_siginfo, pcb);
    return IK_FIX(rv);
  } else
    return ik_errno_to_code();
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_sigtimedwait (ikptr_t s_signo, ikptr_t s_siginfo, ikptr_t s_timeout, ikpcb_t * pcb)
/* Interface to the C function "sigtimedwait()".  Synchronously wait for
   a  queued signal,  with  a  timeout; if  successful  return a  fixnum
   representing a signal number, else return an encoded "errno" value.

   S_SIGNO must be a fixnum representing an interprocess signal code.

   S_SIGINFO must be an instance  of "struct-siginfo_t", which is filled
   with the informations attached to the signal.

   S_TIMEOUT must be an instance of "struct-timespec": it represents the
   maximum interval of time to wait for the signal. */
{
#if ((defined HAVE_SIGEMPTYSET) && (defined HAVE_SIGADDSET) && (defined HAVE_SIGTIMEDWAIT))
  sigset_t		set;
  siginfo_t		info;
  struct timespec	timeout;
  int			rv;
  sigemptyset(&set);
  rv = sigaddset(&set, IK_NUM_TO_SIGNUM(s_signo));
  if (-1 == rv)
    return ik_errno_to_code();
  timeout.tv_sec  = ik_integer_to_long(IK_FIELD(s_timeout, 0));
  timeout.tv_nsec = ik_integer_to_long(IK_FIELD(s_timeout, 1));
  rv = sigtimedwait(&set, &info, &timeout);
  if (0 < rv) {
    posix_siginfo_to_struct(&info, s_siginfo, pcb);
    return IK_FIX(rv);
  } else
    return ik_errno_to_code();
#else
  feature_failure(__func__);
#endif
}


/** --------------------------------------------------------------------
 ** System configuration.
 ** ----------------------------------------------------------------- */

ikptr_t
ikrt_posix_sysconf (ikptr_t s_parameter, ikpcb_t * pcb)
{
#ifdef HAVE_SYSCONF
  long  parameter = ik_integer_to_long(s_parameter);
  long  value;
  errno = 0;
  value = sysconf((int)parameter);
  if (-1 == value)
    return (errno)? ik_errno_to_code() : IK_FALSE_OBJECT;
  else
    return ika_integer_from_long(pcb, value);
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_pathconf (ikptr_t s_pathname, ikptr_t s_parameter, ikpcb_t * pcb)
{
#ifdef HAVE_PATHCONF
  char *pathname  = IK_BYTEVECTOR_DATA_CHARP(s_pathname);
  long  parameter = ik_integer_to_long(s_parameter);
  long  value;
  errno = 0;
  value = pathconf(pathname, (int)parameter);
  if (-1 == value)
    return (errno)? ik_errno_to_code() : IK_FALSE_OBJECT;
  else
    return ika_integer_from_long(pcb, value);
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_fpathconf (ikptr_t s_fd, ikptr_t s_parameter, ikpcb_t * pcb)
{
#ifdef HAVE_FPATHCONF
  long  parameter = ik_integer_to_long(s_parameter);
  long  value;
  errno = 0;
  value = fpathconf(IK_UNFIX(s_fd), (int)parameter);
  if (-1 == value)
    return (errno)? ik_errno_to_code() : IK_FALSE_OBJECT;
  else
    return ika_integer_from_long(pcb, value);
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_confstr (ikptr_t s_parameter, ikpcb_t * pcb)
{
#ifdef HAVE_CONFSTR
  long          parameter = ik_integer_to_long(s_parameter);
  size_t        length_including_zero;
  errno = 0;
  length_including_zero = confstr((int)parameter, NULL, 0);
  if (length_including_zero) {
    ikptr_t       s_result = ika_bytevector_alloc(pcb, (ikuword_t)(length_including_zero-1));
    char *      result   = IK_BYTEVECTOR_DATA_CHARP(s_result);
    confstr((int)parameter, result, length_including_zero);
    return s_result;
  } else
    return ik_errno_to_code();
#else
  feature_failure(__func__);
#endif
}


/** --------------------------------------------------------------------
 ** POSIX message queues.
 ** ----------------------------------------------------------------- */

ikptr_t
ikrt_posix_mq_open (ikptr_t s_name, ikptr_t s_oflag, ikptr_t s_mode, ikptr_t s_attr,
		    ikpcb_t * pcb)
/* Interface to the C function  "mq_open()".  Create a new message queue
   or  open an  existing  one.   If successful  return  a message  queue
   descriptor, else return an encoded "errno" value.

   S_NAME must be a bytevector holding a pathname in ASCII encoding.

   S_OFLAG must be a fixnum representing the inclusive OR composition of
   some of the following  flags: O_RDONLY, O_WRONLY, O_RDWR, O_NONBLOCK,
   O_CREAT, O_EXCL.

   S_MODE  must be  a  fixnum representing  access  permissions for  the
   message queue pathname;  it should be an inclusive  OR composition of
   some  of  the flags:  S_IRUSR,  S_IWUSR,  S_IXUSR, S_IRGRP,  S_IWGRP,
   S_IXGRP, S_IROTH, S_IWOTH, S_IXOTH.

   S_ATTR must be false or  an instance of "struct-mq-attr"; when false:
   the queue is created with platform-dependent default attributes.  */
{
#ifdef HAVE_MQ_OPEN
  const char *		name;
  struct mq_attr	attr;
  struct mq_attr *	attrp;
  mqd_t			rv;
  name = IK_BYTEVECTOR_DATA_CHARP(s_name);
  if (IK_FALSE_OBJECT != s_attr) {
    attr.mq_flags	= ik_integer_to_long(IK_FIELD(s_attr, 0));
    attr.mq_maxmsg	= ik_integer_to_long(IK_FIELD(s_attr, 1));
    attr.mq_msgsize	= ik_integer_to_long(IK_FIELD(s_attr, 2));
    attr.mq_curmsgs	= ik_integer_to_long(IK_FIELD(s_attr, 3));
    attrp = &attr;
  } else
    attrp = NULL;
  errno = 0;
  rv    = mq_open(name, IK_UNFIX(s_oflag), IK_UNFIX(s_mode), attrp);
  return (((mqd_t)-1) != rv)? IK_FIX(rv) : ik_errno_to_code();
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_mq_close (ikptr_t s_mqd)
/* Interface to  the C function  "mq_close()".  Close the  message queue
   referenced by  the descriptor  S_MQD; notice  that the  message queue
   will  still  exist  until  it  is  deleted  with  "mq_unlink()".   If
   successful return  the fixnum  zero, else  return an  encoded "errno"
   value. */
{
#ifdef HAVE_MQ_CLOSE
  int	rv;
  errno = 0;
  rv = mq_close(IK_UNFIX(s_mqd));
  return (0 == rv)? IK_FIX(rv) : ik_errno_to_code();
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_mq_unlink (ikptr_t s_name, ikpcb_t * pcb)
/* Interface to the C function  "mq_unlink()".  Remove the message queue
   whose  name is  S_NAME, which  must  be a  bytevector representing  a
   pathname  in  ASCII  encoding;  the message  queue  name  is  removed
   immediately,  while  the  message  queue  is  removed  when  all  the
   processes  referencing it  close  their  descriptors.  If  successful
   return the fixnum zero, else return an encoded "errno" value. */
{
#ifdef HAVE_MQ_UNLINK
  const char *	name;
  int		rv;
  name = IK_BYTEVECTOR_DATA_CHARP(s_name);
  errno = 0;
  rv = mq_unlink(name);
  return (0 == rv)? IK_FIX(0) : ik_errno_to_code();
#else
  feature_failure(__func__);
#endif
}

/* ------------------------------------------------------------------ */

ikptr_t
ikrt_posix_mq_send (ikptr_t s_mqd, ikptr_t s_message, ikptr_t s_priority)
/* Interface to the C function "mq_send()".   Add a message to the queue
   referenced by the descriptor S_MQD.   If successful return the fixnum
   zero, else return an encoded "errno" value.

   S_MESSAGE must be a Scheme  bytevector representing the message data.
   S_PRIORITY must be an exact integer,  in the range of "unsigned int",
   representing the priority of the message. */
{
#ifdef HAVE_MQ_SEND
  const char *	msg_ptr;
  size_t	msg_len;
  unsigned	priority;
  int		rv;
  msg_ptr	= IK_BYTEVECTOR_DATA_CHARP(s_message);
  msg_len	= IK_BYTEVECTOR_LENGTH(s_message);
  priority	= ik_integer_to_uint(s_priority);
  errno = 0;
  rv = mq_send(IK_UNFIX(s_mqd), msg_ptr, msg_len, priority);
  return (0 == rv)? IK_FIX(0) : ik_errno_to_code();
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_mq_timedsend (ikptr_t s_mqd, ikptr_t s_message, ikptr_t s_priority,
			 ikptr_t s_epoch_timeout)
/* Interface to the  C function "mq_timedsend()".  Add a  message to the
   queue referenced by  the descriptor S_MQD.  If  successful return the
   fixnum zero, else return an encoded "errno" value.

   S_MESSAGE must be a Scheme bytevector representing the message data.

   S_PRIORITY must be an exact integer,  in the range of "unsigned int",
   representing the priority of the message.

   S_EPOCH_TIMEOUT must be an instance of "struct-timespec" representing
   an absolute time since the Epoch: if the queue is in blocking mode, a
   call to this function will block until the timeout expires waiting to
   deliver the message. */
{
#ifdef HAVE_MQ_TIMEDSEND
  const char *		msg_ptr;
  size_t		msg_len;
  unsigned		priority;
  struct timespec	timeout;
  int			rv;
  msg_ptr		= IK_BYTEVECTOR_DATA_CHARP(s_message);
  msg_len		= IK_BYTEVECTOR_LENGTH(s_message);
  priority		= ik_integer_to_uint(s_priority);
  timeout.tv_sec	= (time_t)ik_integer_to_long(IK_FIELD(s_epoch_timeout, 0));
  timeout.tv_nsec	= ik_integer_to_long(IK_FIELD(s_epoch_timeout, 1));
  errno			= 0;
  rv = mq_timedsend(IK_UNFIX(s_mqd), msg_ptr, msg_len, priority, &timeout);
  return (0 == rv)? IK_FIX(0) : ik_errno_to_code();
#else
  feature_failure(__func__);
#endif
}

/* ------------------------------------------------------------------ */

ikptr_t
ikrt_posix_mq_receive (ikptr_t s_mqd, ikptr_t s_message, ikpcb_t * pcb)
/* Interface  to  the  C  function "mq_receive()".   Remove  the  oldest
   message with the  highest priority from the  message queue referenced
   by S_MQD.  If successful return a  pair whose car is an exact integer
   representing the  number of bytes in  the message and whose  cdr is a
   non-negative exact integer representing  the priority of the message,
   else return an encoded "errno" value.

   S_MESSAGE must be  a Scheme bytevector providing the  buffer in which
   the  function will  write the  received message;  its length  must be
   greater  than  the maximum  message  length  specified in  the  queue
   attributes. */
{
#ifdef HAVE_MQ_RECEIVE
  char *	msg_ptr;
  size_t	msg_len;
  unsigned	priority;
  ssize_t	rv;
  msg_ptr	= IK_BYTEVECTOR_DATA_CHARP(s_message);
  msg_len	= IK_BYTEVECTOR_LENGTH(s_message);
  errno = 0;
  rv = mq_receive(IK_UNFIX(s_mqd), msg_ptr, msg_len, &priority);
  if (-1 != rv) {
    ikptr_t	s_pair = ika_pair_alloc(pcb);
    pcb->root0 = &s_pair;
    {
      IK_ASS(IK_CAR(s_pair), ika_integer_from_ssize_t(pcb, rv));
      IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_CAR_PTR(s_pair));

      IK_ASS(IK_CDR(s_pair), ika_integer_from_uint(pcb, priority));
      IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_CDR_PTR(s_pair));
    }
    pcb->root0 = NULL;
    return s_pair;
  } else
    return ik_errno_to_code();
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_mq_timedreceive (ikptr_t s_mqd, ikptr_t s_message, ikptr_t s_epoch_timeout, ikpcb_t * pcb)
/* Interface to  the C function "mq_timedreceive()".   Remove the oldest
   message with the  highest priority from the  message queue referenced
   by S_MQD.  If successful return a  pair whose car is an exact integer
   representing the  number of bytes in  the message and whose  cdr is a
   non-negative exact integer representing  the priority of the message,
   else return an encoded "errno" value.

   S_MESSAGE must be  a Scheme bytevector providing the  buffer in which
   the  function will  write the  received message;  its length  must be
   greater  than  the maximum  message  length  specified in  the  queue
   attrbutes.

   S_EPOCH_TIMEOUT must be an instance of "struct-timespec" representing
   an absolute time since the Epoch: if the queue is in blocking mode, a
   call to this function will block until the timeout expires waiting to
   receive the message. */
{
#ifdef HAVE_MQ_TIMEDRECEIVE
  char *		msg_ptr;
  size_t		msg_len;
  unsigned		priority;
  struct timespec	timeout;
  ssize_t		rv;
  msg_ptr		= IK_BYTEVECTOR_DATA_CHARP(s_message);
  msg_len		= IK_BYTEVECTOR_LENGTH(s_message);
  timeout.tv_sec	= (time_t)ik_integer_to_long(IK_FIELD(s_epoch_timeout, 0));
  timeout.tv_nsec	= ik_integer_to_long(IK_FIELD(s_epoch_timeout, 1));
  errno			= 0;
  rv = mq_timedreceive(IK_UNFIX(s_mqd), msg_ptr, msg_len, &priority, &timeout);
  if (-1 != rv) {
    ikptr_t	s_pair = ika_pair_alloc(pcb);
    pcb->root0 = &s_pair;
    {
      IK_ASS(IK_CAR(s_pair), ika_integer_from_ssize_t(pcb, rv));
      IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_CAR_PTR(s_pair));

      IK_ASS(IK_CDR(s_pair), ika_integer_from_uint(pcb, priority));
      IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_CDR_PTR(s_pair));
    }
    pcb->root0 = NULL;
    return s_pair;
  } else
    return ik_errno_to_code();
#else
  feature_failure(__func__);
#endif
}

/* ------------------------------------------------------------------ */

ikptr_t
ikrt_posix_mq_setattr (ikptr_t s_mqd, ikptr_t s_new_attr, ikptr_t s_old_attr, ikpcb_t * pcb)
/* Interface to the C function "mq_setattr()".  Modify the attributes of
   the message queue referenced by S_MQD.   The new values are read from
   S_NEW_ATTR, which must  be an instance of  "struct-mq-attr".  The old
   values  are  stored in  S_OLD_ATTR,  which  must  be an  instance  of
   "struct-mq-attr".  If successful return  the fixnum zero, else return
   an encoded "errno" value. */
{
#ifdef HAVE_MQ_SETATTR
  struct mq_attr	new_attr = { 0L, 0L, 0L, 0L };
  struct mq_attr	old_attr = { 0L, 0L, 0L, 0L };
  int			rv;
  new_attr.mq_flags	= ik_integer_to_long(IK_FIELD(s_new_attr, 0));
  new_attr.mq_maxmsg	= ik_integer_to_long(IK_FIELD(s_new_attr, 1));
  new_attr.mq_msgsize	= ik_integer_to_long(IK_FIELD(s_new_attr, 2));
  new_attr.mq_curmsgs	= ik_integer_to_long(IK_FIELD(s_new_attr, 3));
  errno = 0;
  rv = mq_setattr(IK_UNFIX(s_mqd), &new_attr, &old_attr);
  if (0 == rv) {
    pcb->root0 = &s_old_attr;
    {
      IK_ASS(IK_FIELD(s_old_attr, 0), ika_integer_from_long(pcb, old_attr.mq_flags));
      IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_FIELD_PTR(s_old_attr, 0));

      IK_ASS(IK_FIELD(s_old_attr, 1), ika_integer_from_long(pcb, old_attr.mq_maxmsg));
      IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_FIELD_PTR(s_old_attr, 1));

      IK_ASS(IK_FIELD(s_old_attr, 2), ika_integer_from_long(pcb, old_attr.mq_msgsize));
      IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_FIELD_PTR(s_old_attr, 2));

      IK_ASS(IK_FIELD(s_old_attr, 3), ika_integer_from_long(pcb, old_attr.mq_curmsgs));
      IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_FIELD_PTR(s_old_attr, 3));
    }
    pcb->root0 = NULL;
    return IK_FIX(0);
  }
  else
    return ik_errno_to_code();
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_mq_getattr (ikptr_t s_mqd, ikptr_t s_attr, ikpcb_t * pcb)
/* Interface to the C  function "mq_getattr()".  Retrieve the attributes
   of the message  queue referenced by S_MQD.  The values  are stored in
   S_ATTR, which must be an instance of "struct-mq-attr".  If successful
   return the fixnum zero, else return an encoded "errno" value. */
{
#ifdef HAVE_MQ_GETATTR
  struct mq_attr	attr = { 0L, 0L, 0L, 0L };
  int			rv;
  errno = 0;
  rv = mq_getattr(IK_UNFIX(s_mqd), &attr);
  if (0 == rv) {
    pcb->root0 = &s_attr;
    {
      IK_ASS(IK_FIELD(s_attr, 0), ika_integer_from_long(pcb, attr.mq_flags));
      IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_FIELD_PTR(s_attr, 0));

      IK_ASS(IK_FIELD(s_attr, 1), ika_integer_from_long(pcb, attr.mq_maxmsg));
      IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_FIELD_PTR(s_attr, 1));

      IK_ASS(IK_FIELD(s_attr, 2), ika_integer_from_long(pcb, attr.mq_msgsize));
      IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_FIELD_PTR(s_attr, 2));

      IK_ASS(IK_FIELD(s_attr, 3), ika_integer_from_long(pcb, attr.mq_curmsgs));
      IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_FIELD_PTR(s_attr, 3));
    }
    return IK_FIX(0);
  } else
    return ik_errno_to_code();
#else
  feature_failure(__func__);
#endif
}


/** --------------------------------------------------------------------
 ** POSIX realtime clock functions.
 ** ----------------------------------------------------------------- */

/* We assume that "clockid_t" can be safely converted to a "long". */

ikptr_t
ikrt_posix_clock_getres (ikptr_t s_clock_id, ikptr_t s_struct_timespec, ikpcb_t * pcb)
{
#ifdef HAVE_CLOCK_GETRES
  clockid_t		clock_id = (clockid_t)ik_integer_to_long(s_clock_id);
  struct timespec	T;
  int			rv;
  errno = 0;
  rv = clock_getres(clock_id, &T);
  if (0 == rv) {
    pcb->root0 = &s_struct_timespec;
    {
      IK_ASS(IK_FIELD(s_struct_timespec, 0), ika_integer_from_long(pcb, (long)T.tv_sec));
      IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_FIELD_PTR(s_struct_timespec, 0));

      IK_ASS(IK_FIELD(s_struct_timespec, 1), ika_integer_from_long(pcb, T.tv_nsec));
      IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_FIELD_PTR(s_struct_timespec, 1));
    }
    pcb->root0 = NULL;
    return IK_FIX(0);
  } else
    return ik_errno_to_code();
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_clock_gettime (ikptr_t s_clock_id, ikptr_t s_struct_timespec, ikpcb_t * pcb)
{
#ifdef HAVE_CLOCK_GETTIME
  clockid_t		clock_id = (clockid_t)ik_integer_to_long(s_clock_id);
  struct timespec	T;
  int			rv;
  errno = 0;
  rv = clock_gettime(clock_id, &T);
  if (0 == rv) {
    pcb->root0 = &s_struct_timespec;
    {
      IK_ASS(IK_FIELD(s_struct_timespec, 0), ika_integer_from_long(pcb, (long)T.tv_sec));
      IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_FIELD_PTR(s_struct_timespec, 0));

      IK_ASS(IK_FIELD(s_struct_timespec, 1), ika_integer_from_long(pcb, T.tv_nsec));
      IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_FIELD_PTR(s_struct_timespec, 1));
    }
    pcb->root0 = NULL;
    return IK_FIX(0);
  } else
    return ik_errno_to_code();
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_clock_settime (ikptr_t s_clock_id, ikptr_t s_struct_timespec, ikpcb_t * pcb)
{
#ifdef HAVE_CLOCK_SETTIME
  clockid_t		clock_id = (clockid_t)ik_integer_to_long(s_clock_id);
  struct timespec	T;
  int			rv;
  errno = 0;
  rv = clock_settime(clock_id, &T);
  if (0 == rv) {
    pcb->root0 = &s_struct_timespec;
    {
      IK_ASS(IK_FIELD(s_struct_timespec, 0), ika_integer_from_long(pcb, (long)T.tv_sec));
      IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_FIELD_PTR(s_struct_timespec, 0));

      IK_ASS(IK_FIELD(s_struct_timespec, 1), ika_integer_from_long(pcb, T.tv_nsec));
      IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_FIELD_PTR(s_struct_timespec, 1));
    }
    pcb->root0 = NULL;
    return IK_FIX(0);
  } else
    return ik_errno_to_code();
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_clock_getcpuclockid (ikptr_t s_pid, ikpcb_t * pcb)
/* Interface  to the  C  function  "clock_getcpuclockid()".  Obtain  the
   identifier of a process' CPU-time  clock; if successful return a pair
   whose car  is an exact  integer representing  the id, else  return an
   encoded  "errno" value.   S_PID  must be  a  fixnum representing  the
   process identifier. */
{
#ifdef HAVE_CLOCK_GETCPUCLOCKID
  pid_t		pid = IK_NUM_TO_PID(s_pid);
  clockid_t	clock_id;
  int		rv;
  errno = 0;
  rv = clock_getcpuclockid(pid, &clock_id);
  if (0 == rv) {
    ikptr_t	s_pair = ika_pair_alloc(pcb);
    pcb->root0 = &s_pair;
    {
      IK_ASS(IK_CAR(s_pair), ika_integer_from_long(pcb, (long)clock_id));
      IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_CAR_PTR(s_pair));

      IK_ASS(IK_CDR(s_pair), IK_FALSE_OBJECT);
      IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_CDR_PTR(s_pair));
    }
    pcb->root0 = NULL;
    return s_pair;
  } else
    return ik_errno_to_code();
#else
  feature_failure(__func__);
#endif
}


/** --------------------------------------------------------------------
 ** POSIX shared memory.
 ** ----------------------------------------------------------------- */

ikptr_t
ikrt_posix_shm_open (ikptr_t s_name, ikptr_t s_oflag, ikptr_t s_mode)
{
#ifdef HAVE_SHM_OPEN
  const char *	name = IK_BYTEVECTOR_DATA_CHARP(s_name);
  int		rv;
  errno = 0;
  rv = shm_open(name, IK_UNFIX(s_oflag), IK_UNFIX(s_mode));
  return (-1 != rv)? IK_FD_TO_NUM(rv) : ik_errno_to_code();
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_shm_unlink (ikptr_t s_name)
{
#ifdef HAVE_SHM_UNLINK
  const char *	name = IK_BYTEVECTOR_DATA_CHARP(s_name);
  int		rv;
  errno = 0;
  rv = shm_unlink(name);
  return (0 == rv)? IK_FIX(0) : ik_errno_to_code();
#else
  feature_failure(__func__);
#endif
}


/** --------------------------------------------------------------------
 ** POSIX semaphores.
 ** ----------------------------------------------------------------- */

ikptr_t
ikrt_posix_sizeof_sem_t (ikpcb_t * pcb)
{
#ifdef HAVE_SEM_OPEN
  /* It is "sizeof(sem_t)  == 16" on my  i686-pc-linux-gnu (Marco Maggi;
    Jul 10, 2012).

    fprintf(stderr, "sem_t = %d\n", sizeof(sem_t));
  */
  return ika_integer_from_int(pcb, sizeof(sem_t));
#else
  feature_failure(__func__);
#endif
}

/* ------------------------------------------------------------------ */

ikptr_t
ikrt_posix_sem_open (ikptr_t s_name, ikptr_t s_oflag, ikptr_t s_mode, ikptr_t s_value, ikpcb_t * pcb)
/* Interface  to the  C function  "sem_open()".  Initialise  and open  a
   named semaphore using the pathname S_NAME, which must be a bytevector
   holding an  ASCII encoded pathname.   If successful return  a pointer
   object  referencing the  semaphore,  else return  an encoded  "errno"
   value.

   S_OFLAG  must  be  a  fixnum  representing  a  bitwise  inclusive  OR
   combination of some of the following values: O_CREAT, O_EXCL, O_RDWR.

   S_MODE  must  be  a  fixnum   representing  a  bitwise  inclusive  OR
   combination  of  some  of  the following  values:  S_IRUSR,  S_IWUSR,
   S_IXUSR, S_IRGRP, S_IWGRP, S_IXGRP, S_IROTH, S_IWOTH, S_IXOTH.

   S_VALUE must be a  exact integer in the range of  the C language type
   "unsigned int".

   Named semaphores must  be closed with "sem_close()"  and removed with
   "sem_unlink()". */
{
#ifdef HAVE_SEM_OPEN
  const char *	name	= IK_BYTEVECTOR_DATA_CHARP(s_name);
  int		oflag	= IK_UNFIX(s_oflag);
  int		mode	= IK_UNFIX(s_mode);
  ik_uint	value	= ik_integer_to_uint(s_value);
  sem_t *	rv;
  errno = 0;
  rv    = sem_open(name, oflag, mode, value);
  if (SEM_FAILED != rv) {
    return ika_pointer_alloc(pcb, (ikuword_t)rv);
  } else
    return ik_errno_to_code();
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_sem_close (ikptr_t s_sem)
/* Interface to the C function "sem_close()".  Close the named semaphore
   referenced by  S_SEM, which must be  a pointer object; note  that the
   semaphore will continue to exist  until "sem_unlink()" is called.  If
   successful return  the fixnum  zero, else  return an  encoded "errno"
   value. */
{
#ifdef HAVE_SEM_CLOSE
  sem_t *	sem = IK_POINTER_DATA_VOIDP(s_sem);
  int		rv;
  errno = 0;
  rv    = sem_close(sem);
  return (0 == rv)? IK_FIX(0) : ik_errno_to_code();
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_sem_unlink (ikptr_t s_name)
/* Interface  to  the  C  function  "sem_unlink()".   Remove  the  named
   semaphore  referenced   by  S_NAME,   which  must  be   a  bytevector
   representing a  pathname in ASCII  encoding; note that  the semaphore
   name is removed  immediately, but the semaphore  itself will continue
   to  exist   until  all  the   processes  referencing  it   will  call
   "sem_close()".  If successful return the  fixnum zero, else return an
   encoded "errno" value. */
{
#ifdef HAVE_SEM_UNLINK
  const char *	name = IK_BYTEVECTOR_DATA_CHARP(s_name);
  int		rv;
  errno = 0;
  rv    = sem_unlink(name);
  return (0 == rv)? IK_FIX(0) : ik_errno_to_code();
#else
  feature_failure(__func__);
#endif
}

/* ------------------------------------------------------------------ */

ikptr_t
ikrt_posix_sem_init (ikptr_t s_sem, ikptr_t s_pshared, ikptr_t s_value, ikpcb_t * pcb)
/* Interface  to the  C  function "sem_init()".   Initialise an  unnamed
   semaphore; if successful return S_SEM  itself, else return an encoded
   "errno" value.

   S_SEM must be a pointer object referencing a memory region big enough
   to hold a C language "sem_t"  data structure; such memory region must
   be allocated in such  a way that it can be  shared among the entities
   interested in accessing the semaphore.

   S_PSHARED  is  interpreted  as  a  boolean  value:  when  false,  the
   semaphore  is meant  to  be  shared among  multiple  threads in  this
   process;  when  true, the  semaphore  is  meant  to be  shared  among
   multiple processes resulting from forking the current process.

   S_VALUE must be an exact integer in  the range of the C language type
   "unsigned int": it represents the initial value of the semaphore.

   Unnamed semaphores must be finalised with "sem_destroy()". */
{
#ifdef HAVE_SEM_INIT
  sem_t *	sem	= IK_POINTER_DATA_VOIDP(s_sem);
  int		pshared = (IK_FALSE_OBJECT != s_pshared);
  unsigned int	value	= ik_integer_to_uint(s_value);
  int		rv;
  errno = 0;
  rv    = sem_init(sem, pshared, value);
  return (0 == rv)? s_sem : ik_errno_to_code();
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_sem_destroy (ikptr_t s_sem)
/* Interface to  the C  function "sem_destroy()".  Finalise  the unnamed
   semaphore referenced  by S_SEM,  which must be  a pointer  object; if
   successful return  the fixnum  zero, else  return an  encoded "errno"
   value. */
{
#ifdef HAVE_SEM_DESTROY
  sem_t *	sem = IK_POINTER_DATA_VOIDP(s_sem);
  int		rv;
  errno = 0;
  rv    = sem_destroy(sem);
  return (0 == rv)? IK_FIX(0) : ik_errno_to_code();
#else
  feature_failure(__func__);
#endif
}

/* ------------------------------------------------------------------ */

ikptr_t
ikrt_posix_sem_post (ikptr_t s_sem)
/* Interface  to the  C function  "sem_post()".  Increment  (unlock) the
   unnamed  semaphore  referenced by  S_SEM,  which  must be  a  pointer
   object; if successful return the  fixnum zero, else return an encoded
   "errno" value. */
{
#ifdef HAVE_SEM_POST
  sem_t *	sem = IK_POINTER_DATA_VOIDP(s_sem);
  int		rv;
  errno = 0;
  rv    = sem_post(sem);
  return (0 == rv)? IK_FIX(0) : ik_errno_to_code();
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_sem_wait (ikptr_t s_sem)
/* Interface  to  the C  function  "sem_wait()".   Decrement (lock)  the
   unnamed  semaphore  referenced by  S_SEM,  which  must be  a  pointer
   object, until  the semaphore  is unlocked;  if successful  return the
   fixnum zero, else return an encoded "errno" value. */
{
#ifdef HAVE_SEM_WAIT
  sem_t *	sem = IK_POINTER_DATA_VOIDP(s_sem);
  int		rv;
  errno = 0;
  rv    = sem_wait(sem);
  return (0 == rv)? IK_FIX(0) : ik_errno_to_code();
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_sem_trywait (ikptr_t s_sem)
/* Interface to  the C  function "sem_trywait()".  Decrement  (lock) the
   unnamed  semaphore  referenced by  S_SEM,  which  must be  a  pointer
   object;  if successful  in locking  return the  boolean true,  if the
   semaphore is already locked return  the boolean false, else return an
   encoded "errno" value. */
{
#ifdef HAVE_SEM_TRYWAIT
  sem_t *	sem = IK_POINTER_DATA_VOIDP(s_sem);
  int		rv;
  errno = 0;
  rv    = sem_trywait(sem);
  if (0 == rv)
    return IK_TRUE_OBJECT;
  else if (EAGAIN == errno)
    return IK_FALSE_OBJECT;
  else
    return ik_errno_to_code();
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_sem_timedwait (ikptr_t s_sem, ikptr_t s_abs_timeout)
/* Interface to the C  function "sem_timedwait()".  Attempt to decrement
   (lock) the  unnamed semaphore  referenced by S_SEM,  which must  be a
   pointer object, with a timeout.   If successful in locking return the
   boolean  true; if  the  semaphore is  already locked  and  it is  not
   unlocked  before the  timeout expiration:  return the  boolean false;
   else return an encoded "errno" value.

   S_ABS_TIMEOUT must  be an instance of  "struct-timespec" representing
   the absolute timeout since the Epoch. */
{
#ifdef HAVE_SEM_TIMEDWAIT
  sem_t *		sem = IK_POINTER_DATA_VOIDP(s_sem);
  struct timespec	abs_timeout;
  int			rv;
  abs_timeout.tv_sec	= (time_t)ik_integer_to_long(IK_FIELD(s_abs_timeout, 0));
  abs_timeout.tv_nsec	=         ik_integer_to_long(IK_FIELD(s_abs_timeout, 1));
  errno = 0;
  rv    = sem_timedwait(sem, &abs_timeout);
  if (0 == rv)
    return IK_TRUE_OBJECT;
  else if (ETIMEDOUT == errno)
    return IK_FALSE_OBJECT;
  else
    return ik_errno_to_code();
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_sem_getvalue (ikptr_t s_sem, ikpcb_t * pcb)
/* Interface to  the C function "sem_getvalue()".   Retrieve the current
   value of the  semaphore referenced by S_SEM, which must  be a pointer
   object; if  successful return a  pair whose  car is an  exact integer
   representing the value and whose cdr  is set to false, else return an
   encoded "errno" value. */
{
#ifdef HAVE_SEM_GETVALUE
  sem_t *	sem = IK_POINTER_DATA_VOIDP(s_sem);
  int		value;
  int		rv;
  errno = 0;
  rv    = sem_getvalue(sem, &value);
  if (0 == rv) {
    ikptr_t	s_pair = ika_pair_alloc(pcb);
    pcb->root0 = &s_pair;
    {
      IK_ASS(IK_CAR(s_pair), ika_integer_from_int(pcb, value));
      IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_CAR_PTR(s_pair));

      IK_ASS(IK_CDR(s_pair), IK_FALSE_OBJECT);
      IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_CDR_PTR(s_pair));
    }
    pcb->root0 = NULL;
    return s_pair;
  } else
    return ik_errno_to_code();
#else
  feature_failure(__func__);
#endif
}


/** --------------------------------------------------------------------
 ** POSIX per-process timers.
 ** ----------------------------------------------------------------- */

ikptr_t
ikrt_posix_timer_create (ikptr_t s_clock_id, ikptr_t s_sigevent, ikpcb_t * pcb)
/* Interface  to   the  C  function  "timer_create()".    Create  a  new
   per-process interval timer, initially  disarmed; if successful return
   a  pair  whose  car  is  an  exact  integer  representing  the  timer
   identifier and  whose cdr  is false; else  return an  encoded "errno"
   value.

   S_CLOCK_ID must be an exact  integer representing the identifier of a
   clock to  be used to  measure time; it can  be one of  the constants:
   CLOCK_REALTIME,       CLOCK_MONOTONIC,      CLOCK_PROCESS_CPUTIME_ID,
   CLOCK_THREAD_CPUTIME_ID or the return value of CLOCK-GETCPUCLOCKID.

   S_SIGEVENT  can   be  false  or  an   instance  of  "struct-sigevent"
   specifying how the process is  notified of timer events.

   * When false: the call sets up  the notification as with a C language
     "struct  sigevent"  having:  "sigev_notify"  set  to  SIGEV_SIGNAL,
     "sigev_signo" set  to SIGALRM,  "sigev.sival_int" set to  the timer
     identifier.

   * When a  "struct-sigevent" instance: at present,  the only supported
     method is with "sigev_notify" set to SIGEV_SIGNAL and "sigev_signo"
     set to the signal number, all the other fields being zero. */
{
#ifdef HAVE_TIMER_CREATE
  clockid_t		clock_id = (clockid_t)ik_integer_to_long(s_clock_id);
  struct sigevent	sev;
  struct sigevent *	sevp;
  timer_t		timer_id;
  int			rv;
  if (IK_FALSE_OBJECT == s_sigevent) {
    sevp = NULL;
  } else {
    sev.sigev_notify		= ik_integer_to_int(IK_FIELD(s_sigevent, 0));
    sev.sigev_signo		= ik_integer_to_int(IK_FIELD(s_sigevent, 1));
    sev.sigev_value.sival_int	= 0;
    sev.sigev_notify_attributes	= NULL;
#if 0 /* On  GNU+Linux "sigev_notify_function"  shares the  storage with
	 "sigev_notify_attributes". */
    sev.sigev_notify_function	= NULL;
#endif
#if 0 /* On GNU+Linux "sigev_notify_thread_id" is not present. */
    sev.sigev_notify_thread_id	= (pid_t)0;
#endif
    sevp = &sev;
  }
  errno = 0;
  rv = timer_create(clock_id, sevp, &timer_id);
  if (0 == rv) {
    ikptr_t	s_pair = ika_pair_alloc(pcb);
    pcb->root0 = &s_pair;
    {
      IK_ASS(IK_CAR(s_pair), ika_integer_from_long(pcb, (long)timer_id));
      IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_CAR_PTR(s_pair));

      IK_ASS(IK_CDR(s_pair), IK_FALSE_OBJECT);
    }
    pcb->root0 = NULL;
    return s_pair;
  } else
    return ik_errno_to_code();
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_timer_delete (ikptr_t s_timer_id)
/* Interface  to  the C  function  "timer_delete()".   Delete the  timer
   referenced by S_TIMER_ID; if successful  return the fixnum zero, else
   return an encoded "errno" value. */
{
#ifdef HAVE_TIMER_DELETE
  timer_t	timer_id = (timer_t)ik_integer_to_long(s_timer_id);
  int		rv;
  errno = 0;
  rv = timer_delete(timer_id);
  return (0 == rv)? IK_FIX(0) : ik_errno_to_code();
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_timer_settime (ikptr_t s_timer_id, ikptr_t s_flags,
			  ikptr_t s_new_timer_spec, ikptr_t s_old_timer_spec,
			  ikpcb_t * pcb)
/* Interface to  the C  function "timer_settime()".   Arms or  disarms a
   timer; if successful  return the fixnum zero, else  return an encoded
   "errno" value.

   S_TIMER_ID must be an exact  integer representing a timer identifier.
   S_FLAGS must be the fixnum zero or the value of TIMER_ABSTIME.

   S_NEW_TIMER_SPEC must be an instance of "struct-itimerspec" and it is
   used to arm or disarm the timer.

   S_OLD_TIMER_SPEC must be false or an instance of "struct-itimerspec";
   in the  latter case:  the instance  is mutated  to represent  the old
   timer specification. */
{
#ifdef HAVE_TIMER_SETTIME
  timer_t		timer_id      = (timer_t)ik_integer_to_long(s_timer_id);
  ikptr_t			s_it_interval = IK_FIELD(s_new_timer_spec, 0);
  ikptr_t			s_it_value    = IK_FIELD(s_new_timer_spec, 1);
  struct itimerspec	new_spec;
  struct itimerspec	old_spec;
  int			rv;
  new_spec.it_interval.tv_sec	= (time_t)ik_integer_to_long(IK_FIELD(s_it_interval, 0));
  new_spec.it_interval.tv_nsec	=         ik_integer_to_long(IK_FIELD(s_it_interval, 1));
  new_spec.it_value.tv_sec	= (time_t)ik_integer_to_long(IK_FIELD(s_it_value,    0));
  new_spec.it_value.tv_nsec	=         ik_integer_to_long(IK_FIELD(s_it_value,    1));
  errno = 0;
  rv    = timer_settime(timer_id, IK_UNFIX(s_flags), &new_spec, &old_spec);
  if (0 == rv) {
    if (IK_FALSE_OBJECT != s_old_timer_spec) {
      pcb->root0 = &s_old_timer_spec;
      {
	IK_ASS(IK_FIELD(IK_FIELD(s_old_timer_spec, 0), 0),   ika_integer_from_long(pcb, (long)old_spec.it_interval.tv_sec));
	IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_FIELD_PTR(IK_FIELD(s_old_timer_spec, 0), 0));

	IK_ASS(IK_FIELD(IK_FIELD(s_old_timer_spec, 0), 1),   ika_integer_from_long(pcb,       old_spec.it_interval.tv_nsec));
	IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_FIELD_PTR(IK_FIELD(s_old_timer_spec, 0), 1));

	IK_ASS(IK_FIELD(IK_FIELD(s_old_timer_spec, 1), 0),   ika_integer_from_long(pcb, (long)old_spec.it_value.tv_sec));
	IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_FIELD_PTR(IK_FIELD(s_old_timer_spec, 1), 0));

	IK_ASS(IK_FIELD(IK_FIELD(s_old_timer_spec, 1), 1),   ika_integer_from_long(pcb,       old_spec.it_value.tv_nsec));
	IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_FIELD_PTR(IK_FIELD(s_old_timer_spec, 1), 1));
      }
      pcb->root0 = NULL;
    }
    return IK_FIX(0);
  } else
    return ik_errno_to_code();
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_timer_gettime (ikptr_t s_timer_id, ikptr_t s_curr_timer_spec, ikpcb_t * pcb)
/* Interface to the C  function "timer_gettime()".  Retrieve the current
   timer  specification associated  to  the  identifier S_TIMER_ID.   If
   successful return  the fixnum  zero, else  return an  encoded "errno"
   value.

   S_CURR_TIMER_SPEC must  be an instance of  "struct-itimerspec", which
   is filled with the current timer specification.  */
{
#ifdef HAVE_TIMER_GETTIME
  timer_t		timer_id      = (timer_t)ik_integer_to_long(s_timer_id);
  struct itimerspec	curr_spec;
  int			rv;
  errno = 0;
  rv    = timer_gettime(timer_id, &curr_spec);
  if (0 == rv) {
    pcb->root0 = &s_curr_timer_spec;
    {
      IK_ASS(IK_FIELD(IK_FIELD(s_curr_timer_spec, 0), 0), ika_integer_from_long(pcb, (long)curr_spec.it_interval.tv_sec));
      IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_FIELD_PTR(IK_FIELD(s_curr_timer_spec, 0), 0));

      IK_ASS(IK_FIELD(IK_FIELD(s_curr_timer_spec, 0), 1), ika_integer_from_long(pcb,       curr_spec.it_interval.tv_nsec));
      IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_FIELD_PTR(IK_FIELD(s_curr_timer_spec, 0), 1));

      IK_ASS(IK_FIELD(IK_FIELD(s_curr_timer_spec, 1), 0), ika_integer_from_long(pcb, (long)curr_spec.it_value.tv_sec));
      IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_FIELD_PTR(IK_FIELD(s_curr_timer_spec, 1), 0));

      IK_ASS(IK_FIELD(IK_FIELD(s_curr_timer_spec, 1), 1), ika_integer_from_long(pcb,       curr_spec.it_value.tv_nsec));
      IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_FIELD_PTR(IK_FIELD(s_curr_timer_spec, 1), 1));
    }
    pcb->root0 = NULL;
    return IK_FIX(0);
  } else
    return ik_errno_to_code();
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_timer_getoverrun (ikptr_t s_timer_id, ikpcb_t * pcb)
/* Interface to the C  function "timer_getoverrun()".  Get overrun count
   for  the  timer referenced  by  S_TIMER_ID;  if successful  return  a
   non-negative  exact integer  representing  the overrun  count of  the
   specified timer, else return an encoded "errno" value. */
{
#ifdef HAVE_TIMER_GETOVERRUN
  timer_t	timer_id      = (timer_t)ik_integer_to_long(s_timer_id);
  int		rv;
  errno = 0;
  rv    = timer_getoverrun(timer_id);
  if (-1 != rv) {
    return ika_integer_from_int(pcb, rv);
  } else
    return ik_errno_to_code();
#else
  feature_failure(__func__);
#endif
}


/** --------------------------------------------------------------------
 ** Resource usage.
 ** ----------------------------------------------------------------- */

ikptr_t
ikrt_posix_RLIM_INFINITY (ikpcb_t * pcb)
{
#ifdef RLIM_INFINITY
  return ika_integer_from_uint64(pcb, RLIM_INFINITY);
#else
  return IK_FALSE_OBJECT;
#endif
}

ikptr_t
ikrt_posix_setrlimit (ikptr_t s_resource, ikptr_t s_rlim)
{
#ifdef HAVE_SETRLIMIT
  int		resource = ik_integer_to_int(s_resource);
  struct rlimit	rlim;
  int		rv;
  switch (sizeof(rlim_t)) {
  case 4:
    rlim.rlim_cur	= ik_integer_to_uint32(IK_FIELD(s_rlim, 0));
    rlim.rlim_max	= ik_integer_to_uint32(IK_FIELD(s_rlim, 1));
    break;
  case 8:
    rlim.rlim_cur	= ik_integer_to_uint64(IK_FIELD(s_rlim, 0));
    rlim.rlim_max	= ik_integer_to_uint64(IK_FIELD(s_rlim, 1));
    break;
  default:
    errno = EINVAL;
    return ik_errno_to_code();
  }
  errno = 0;
  rv    = setrlimit(resource, &rlim);
  return (0 == rv)? IK_FIX(0) : ik_errno_to_code();
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_getrlimit (ikptr_t s_resource, ikptr_t s_rlim, ikpcb_t * pcb)
{
#ifdef HAVE_GETRLIMIT
  int		resource = ik_integer_to_int(s_resource);
  struct rlimit	rlim;
  int		rv;
  errno = 0;
  rv    = getrlimit(resource, &rlim);
  if (0 == rv) {
    switch (sizeof(rlim_t)) {
    case 4:
      pcb->root0 = &s_rlim;
      {
	IK_ASS(IK_FIELD(s_rlim, 0), ika_integer_from_uint32(pcb, rlim.rlim_cur));
	IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_FIELD_PTR(s_rlim, 0));

	IK_ASS(IK_FIELD(s_rlim, 1), ika_integer_from_uint32(pcb, rlim.rlim_max));
	IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_FIELD_PTR(s_rlim, 1));
      }
      pcb->root0 = NULL;
      break;
    case 8:
      pcb->root0 = &s_rlim;
      {
	IK_ASS(IK_FIELD(s_rlim, 0), ika_integer_from_uint64(pcb, rlim.rlim_cur));
	IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_FIELD_PTR(s_rlim, 0));

	IK_ASS(IK_FIELD(s_rlim, 1), ika_integer_from_uint64(pcb, rlim.rlim_max));
	IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_FIELD_PTR(s_rlim, 1));
      }
      pcb->root0 = NULL;
      break;
    default:
      errno = EINVAL;
      return ik_errno_to_code();
    }
    return IK_FIX(0);
  } else
    return ik_errno_to_code();
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_getrusage (ikptr_t s_processes, ikptr_t s_rusage, ikpcb_t * pcb)
#define VICARE_POSIX_STRUCT_RUSAGE_RU_UTIME	0
#define VICARE_POSIX_STRUCT_RUSAGE_RU_STIME	1
#define VICARE_POSIX_STRUCT_RUSAGE_RU_MAXRSS	2
#define VICARE_POSIX_STRUCT_RUSAGE_RU_IXRSS	3
#define VICARE_POSIX_STRUCT_RUSAGE_RU_IDRSS	4
#define VICARE_POSIX_STRUCT_RUSAGE_RU_ISRSS	5
#define VICARE_POSIX_STRUCT_RUSAGE_RU_MINFLT	6
#define VICARE_POSIX_STRUCT_RUSAGE_RU_MAJFLT	7
#define VICARE_POSIX_STRUCT_RUSAGE_RU_NSWAP	8
#define VICARE_POSIX_STRUCT_RUSAGE_RU_INBLOCK	9
#define VICARE_POSIX_STRUCT_RUSAGE_RU_OUBLOCK	10
#define VICARE_POSIX_STRUCT_RUSAGE_RU_MSGSND	11
#define VICARE_POSIX_STRUCT_RUSAGE_RU_MSGRCV	12
#define VICARE_POSIX_STRUCT_RUSAGE_RU_NSIGNALS	13
#define VICARE_POSIX_STRUCT_RUSAGE_RU_NVCSW	14
#define VICARE_POSIX_STRUCT_RUSAGE_RU_NIVCSW	15
{
#ifdef HAVE_GETRUSAGE
  int		processes = ik_integer_to_int(s_processes);
  struct rusage	usage;
  int		rv;
  errno = 0;
  rv    = getrusage(processes, &usage);
  if (0 == rv) {
#ifdef HAVE_RUSAGE_RU_UTIME
    IK_ASS(IK_FIELD(IK_FIELD(s_rusage,VICARE_POSIX_STRUCT_RUSAGE_RU_UTIME),0),
	   ika_integer_from_long(pcb,usage.ru_utime.tv_sec));
    IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_FIELD_PTR(IK_FIELD(s_rusage,VICARE_POSIX_STRUCT_RUSAGE_RU_UTIME), 0));

    IK_ASS(IK_FIELD(IK_FIELD(s_rusage,VICARE_POSIX_STRUCT_RUSAGE_RU_UTIME),1),
	   ika_integer_from_long(pcb,usage.ru_utime.tv_sec));
    IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_FIELD_PTR(IK_FIELD(s_rusage,VICARE_POSIX_STRUCT_RUSAGE_RU_UTIME), 1));
#endif
#ifdef HAVE_RUSAGE_RU_STIME
    IK_ASS(IK_FIELD(IK_FIELD(s_rusage,VICARE_POSIX_STRUCT_RUSAGE_RU_STIME),0),
	   ika_integer_from_long(pcb,usage.ru_stime.tv_sec));
    IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_FIELD_PTR(IK_FIELD(s_rusage,VICARE_POSIX_STRUCT_RUSAGE_RU_STIME), 0));

    IK_ASS(IK_FIELD(IK_FIELD(s_rusage,VICARE_POSIX_STRUCT_RUSAGE_RU_STIME),1),
	   ika_integer_from_long(pcb,usage.ru_stime.tv_sec));
    IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_FIELD_PTR(IK_FIELD(s_rusage,VICARE_POSIX_STRUCT_RUSAGE_RU_STIME), 1));
#endif
#ifdef HAVE_RUSAGE_RU_MAXRSS
    IK_ASS(IK_FIELD(s_rusage,VICARE_POSIX_STRUCT_RUSAGE_RU_MAXRSS), ika_integer_from_long(pcb, usage.ru_maxrss));
    IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_FIELD_PTR(s_rusage, VICARE_POSIX_STRUCT_RUSAGE_RU_MAXRSS));
#endif
#ifdef HAVE_RUSAGE_RU_IXRSS
    IK_ASS(IK_FIELD(s_rusage,VICARE_POSIX_STRUCT_RUSAGE_RU_IXRSS),
	   ika_integer_from_long(pcb, usage.ru_ixrss));
    IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_FIELD_PTR(s_rusage,VICARE_POSIX_STRUCT_RUSAGE_RU_IXRSS));
#endif
#ifdef HAVE_RUSAGE_RU_IDRSS
    IK_ASS(IK_FIELD(s_rusage,VICARE_POSIX_STRUCT_RUSAGE_RU_IDRSS),
	   ika_integer_from_long(pcb, usage.ru_idrss));
    IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_FIELD_PTR(s_rusage,VICARE_POSIX_STRUCT_RUSAGE_RU_IDRSS));
#endif
#ifdef HAVE_RUSAGE_RU_ISRSS
    IK_ASS(IK_FIELD(s_rusage,VICARE_POSIX_STRUCT_RUSAGE_RU_ISRSS),
	   ika_integer_from_long(pcb, usage.ru_isrss));
    IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_FIELD_PTR(s_rusage,VICARE_POSIX_STRUCT_RUSAGE_RU_ISRSS));
#endif
#ifdef HAVE_RUSAGE_RU_MINFLT
    IK_ASS(IK_FIELD(s_rusage,VICARE_POSIX_STRUCT_RUSAGE_RU_MINFLT),
	   ika_integer_from_long(pcb, usage.ru_minflt));
    IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_FIELD_PTR(s_rusage,VICARE_POSIX_STRUCT_RUSAGE_RU_MINFLT));
#endif
#ifdef HAVE_RUSAGE_RU_MAJFLT
    IK_ASS(IK_FIELD(s_rusage,VICARE_POSIX_STRUCT_RUSAGE_RU_MAJFLT),
	   ika_integer_from_long(pcb, usage.ru_majflt));
    IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_FIELD_PTR(s_rusage,VICARE_POSIX_STRUCT_RUSAGE_RU_MAJFLT));
#endif
#ifdef HAVE_RUSAGE_RU_NSWAP
    IK_ASS(IK_FIELD(s_rusage,VICARE_POSIX_STRUCT_RUSAGE_RU_NSWAP),
	   ika_integer_from_long(pcb, usage.ru_nswap));
    IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_FIELD_PTR(s_rusage,VICARE_POSIX_STRUCT_RUSAGE_RU_NSWAP));
#endif
#ifdef HAVE_RUSAGE_RU_INBLOCK
    IK_ASS(IK_FIELD(s_rusage,VICARE_POSIX_STRUCT_RUSAGE_RU_INBLOCK),
	   ika_integer_from_long(pcb, usage.ru_inblock));
    IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_FIELD_PTR(s_rusage,VICARE_POSIX_STRUCT_RUSAGE_RU_INBLOCK));
#endif
#ifdef HAVE_RUSAGE_RU_OUBLOCK
    IK_ASS(IK_FIELD(s_rusage,VICARE_POSIX_STRUCT_RUSAGE_RU_OUBLOCK),
	   ika_integer_from_long(pcb, usage.ru_oublock));
    IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_FIELD_PTR(s_rusage,VICARE_POSIX_STRUCT_RUSAGE_RU_OUBLOCK));
#endif
#ifdef HAVE_RUSAGE_RU_MSGSND
    IK_ASS(IK_FIELD(s_rusage,VICARE_POSIX_STRUCT_RUSAGE_RU_MSGSND),
	   ika_integer_from_long(pcb, usage.ru_msgsnd));
    IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_FIELD_PTR(s_rusage,VICARE_POSIX_STRUCT_RUSAGE_RU_MSGSND));
#endif
#ifdef HAVE_RUSAGE_RU_MSGRCV
    IK_ASS(IK_FIELD(s_rusage,VICARE_POSIX_STRUCT_RUSAGE_RU_MSGRCV),
	   ika_integer_from_long(pcb, usage.ru_msgrcv));
    IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_FIELD_PTR(s_rusage,VICARE_POSIX_STRUCT_RUSAGE_RU_MSGRCV));
#endif
#ifdef HAVE_RUSAGE_RU_NSIGNALS
    IK_ASS(IK_FIELD(s_rusage,VICARE_POSIX_STRUCT_RUSAGE_RU_NSIGNALS),
	   ika_integer_from_long(pcb, usage.ru_nsignals));
    IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_FIELD_PTR(s_rusage,VICARE_POSIX_STRUCT_RUSAGE_RU_NSIGNALS));
#endif
#ifdef HAVE_RUSAGE_RU_NVCSW
    IK_ASS(IK_FIELD(s_rusage,VICARE_POSIX_STRUCT_RUSAGE_RU_NVCSW),
	   ika_integer_from_long(pcb, usage.ru_nvcsw));
    IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_FIELD_PTR(s_rusage,VICARE_POSIX_STRUCT_RUSAGE_RU_NVCSW));
#endif
#ifdef HAVE_RUSAGE_RU_NIVCSW
    IK_ASS(IK_FIELD(s_rusage,VICARE_POSIX_STRUCT_RUSAGE_RU_NIVCSW),
	   ika_integer_from_long(pcb, usage.ru_nivcsw));
    IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_FIELD_PTR(s_rusage,VICARE_POSIX_STRUCT_RUSAGE_RU_NIVCSW));
#endif
    return IK_FIX(0);
  } else
    return ik_errno_to_code();
#else
  feature_failure(__func__);
#endif
}


/** --------------------------------------------------------------------
 ** Host to/from network byte order.
 ** ----------------------------------------------------------------- */

ikptr_t
ikrt_posix_htonl (ikptr_t s_host_long, ikpcb_t * pcb)
{
#ifdef HAVE_HTONL
  uint32_t	in = ik_integer_to_uint32(s_host_long);
  uint32_t	rv;
  rv = htonl(in);
  return ika_integer_from_uint32(pcb, rv);
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_htons (ikptr_t s_host_long, ikpcb_t * pcb)
{
#ifdef HAVE_HTONS
  uint16_t	in = ik_integer_to_uint16(s_host_long);
  uint16_t	rv;
  rv = htons(in);
  return ika_integer_from_uint16(pcb, rv);
#else
  feature_failure(__func__);
#endif
}

/* ------------------------------------------------------------------ */

ikptr_t
ikrt_posix_ntohl (ikptr_t s_host_long, ikpcb_t * pcb)
{
#ifdef HAVE_NTOHL
  uint32_t	in = ik_integer_to_uint32(s_host_long);
  uint32_t	rv;
  rv = ntohl(in);
  return ika_integer_from_uint32(pcb, rv);
#else
  feature_failure(__func__);
#endif
}
ikptr_t
ikrt_posix_ntohs (ikptr_t s_host_long, ikpcb_t * pcb)
{
#ifdef HAVE_NTOHS
  uint16_t	in = ik_integer_to_uint16(s_host_long);
  uint16_t	rv;
  rv = ntohs(in);
  return ika_integer_from_uint16(pcb, rv);
#else
  feature_failure(__func__);
#endif
}


/** --------------------------------------------------------------------
 ** Name and informations about current kernel
 ** ----------------------------------------------------------------- */

#define IK_UTSNAME_SYSNAME(STRU)		IK_FIELD((STRU),0)
#define IK_UTSNAME_NODENAME(STRU)		IK_FIELD((STRU),1)
#define IK_UTSNAME_RELEASE(STRU)		IK_FIELD((STRU),2)
#define IK_UTSNAME_VERSION(STRU)		IK_FIELD((STRU),3)
#define IK_UTSNAME_MACHINE(STRU)		IK_FIELD((STRU),4)

#define IK_UTSNAME_SYSNAME_PTR(STRU)		IK_FIELD_PTR((STRU),0)
#define IK_UTSNAME_NODENAME_PTR(STRU)		IK_FIELD_PTR((STRU),1)
#define IK_UTSNAME_RELEASE_PTR(STRU)		IK_FIELD_PTR((STRU),2)
#define IK_UTSNAME_VERSION_PTR(STRU)		IK_FIELD_PTR((STRU),3)
#define IK_UTSNAME_MACHINE_PTR(STRU)		IK_FIELD_PTR((STRU),4)

ikptr_t
ikrt_posix_uname (ikptr_t s_struct, ikpcb_t * pcb)
{
#ifdef HAVE_UNAME
  struct utsname	stru;
  int			rv;
  errno = 0;
  rv    = uname(&stru);
  if (0 == rv) {
    pcb->root0 = &s_struct;
    {
      IK_ASS(IK_UTSNAME_SYSNAME(s_struct),	ika_string_from_cstring(pcb, stru.sysname));
      IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_UTSNAME_SYSNAME_PTR(s_struct));

      IK_ASS(IK_UTSNAME_NODENAME(s_struct),	ika_string_from_cstring(pcb, stru.nodename));
      IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_UTSNAME_NODENAME_PTR(s_struct));

      IK_ASS(IK_UTSNAME_RELEASE(s_struct),	ika_string_from_cstring(pcb, stru.release));
      IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_UTSNAME_RELEASE_PTR(s_struct));

      IK_ASS(IK_UTSNAME_VERSION(s_struct),	ika_string_from_cstring(pcb, stru.version));
      IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_UTSNAME_VERSION_PTR(s_struct));

      IK_ASS(IK_UTSNAME_MACHINE(s_struct),	ika_string_from_cstring(pcb, stru.machine));
      IK_SIGNAL_DIRT_IN_PAGE_OF_POINTER(pcb, IK_UTSNAME_MACHINE_PTR(s_struct));
    }
    pcb->root0 = NULL;
    return IK_FALSE;
  } else {
    return ik_errno_to_code();
  }
#else
  feature_failure(__func__);
#endif
}


/** --------------------------------------------------------------------
 ** Miscellaneous functions.
 ** ----------------------------------------------------------------- */

/* end of file */
