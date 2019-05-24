function! pants#Pants(...)
  let pants = findfile('pants', '.;')
  if strlen(pants) == 0
    echoerr "pants not found"
    return 1
  end
  let pants = fnamemodify(pants, ':p')
  if !executable(pants)
    echoerr pants . " not executable"
    return 1
  end

  execute 'cd' fnameescape(fnamemodify(pants, ':h'))

  let build = findfile('BUILD', '.;')
  let target = fnamemodify(build, ':h')

  let args = ""
  if a:0 == 0
    let goal = "compile"
  elseif a:0 == 1
    let goal = a:1
  else
    let goal = a:1
    let target = substitute(a:2, "\\.", target, "")
    let args = join(a:000[2:])
  endif

  let makeprg_old=&makeprg
  let errorformat_old=&errorformat
  let &makeprg = "./pants --no-colors " . goal . " " . args . " " . target
  let &errorformat = "
      \%E\ %#[error]\ %f:%l:%c:\ %m,%Z\ %#[error]\ %p^,%-C %#[error]\ %m,
      \%W\ %#[warn]\ %f:%l:%c:\ %m,%Z\ %#[warn]\ %p^,%-C %#[warn]\ %m,
      \%E\ %#%n)\ %m,
      \%-G%.%#"

  try
    if has('nvim') && exists(":Neomake")
      Neomake!
    elseif exists("g:loaded_dispatch")
      Make
    else
      make
    endif
  finally
    let &makeprg=makeprg_old
    let &errorformat=errorformat_old
    cd -
  endtry
endfunction

function! pants#Junit(...)
  let path = bufname("%")
  let start_i = strridx(path, "/com/") + 1
  let end_i = strridx(path, ".") - 1 " drop the file extension
  let classname = substitute(path[start_i:end_i], "/", ".", "g")

  if a:0 == 0
    let test = classname
  elseif stridx(a:1, ".") == -1
    "drop the classname to get just the package
    let package = split(classname, '\.')[0:-2]
    let test = join(package + [a:1], ".")
  else
    let test = a:1
  endif

  call pants#Pants("test.junit", ".", "--test-junit-output-mode=FAILURE_ONLY", "--test=" . test)
endfunction
