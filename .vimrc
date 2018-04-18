syntax on
set number
set autoindent
set expandtab
set tabstop=2
set ambiwidth=double
set virtualedit=block "文字のないところもカーソルの移動
set whichwrap=b,s,[,],<,> "カーソルの回り込み
set backspace=indent,eol,start
set hidden "保存してなくても他のファイルを開けるように
set list
set listchars=tab:»-,trail:-,extends:»,precedes:«,nbsp:%
set belloff=all
set clipboard+=unnamed
set smartindent "改行の前の行の構文をチェックしてインデントを増減する
set shiftwidth=2 "自動インデントでずれる幅
set noswapfile
" 括弧自動補完とエンター後のインデントを深く
inoremap { {}<Left>
inoremap {<Enter> {}<Left><CR><ESC><S-o>
inoremap ( ()<ESC>i
inoremap (<Enter> ()<Left><CR><ESC><S-o>
"クリップボードからのペーストの際、なし崩し的にインデントが成されるのを停止する
if &term =~ "xterm"
    let &t_SI .= "\e[?2004h"
    let &t_EI .= "\e[?2004l"
    let &pastetoggle = "\e[201~"

    function XTermPasteBegin(ret)
        set paste
        return a:ret
    endfunction

    inoremap <special> <expr> <Esc>[200~ XTermPasteBegin("")
endif
" 全角スペース・行末のスペース・タブの可視化
if has("syntax")
    syntax on

    " PODバグ対策
    syn sync fromstart

    function! ActivateInvisibleIndicator()
        " 下の行の"　"は全角スペース
        syntax match InvisibleJISX0208Space "　" display containedin=ALL
        highlight InvisibleJISX0208Space term=underline ctermbg=Blue guibg=darkgray gui=underline
        "syntax match InvisibleTrailedSpace "[ \t]\+$" display containedin=ALL
        "highlight InvisibleTrailedSpace term=underline ctermbg=Red guibg=NONE gui=undercurl guisp=darkorange
        "syntax match InvisibleTab "\t" display containedin=ALL
        "highlight InvisibleTab term=underline ctermbg=white gui=undercurl guisp=darkslategray
    endfunction

    augroup invisible
        autocmd! invisible
        autocmd BufNew,BufRead * call ActivateInvisibleIndicator()
    augroup END
endif
" NeoBundle設定
" Note: Skip initialization for vim-tiny or vim-small.
if 0 | endif

if &compatible
  set nocompatible               " Be iMproved
endif

" Required:
set runtimepath+=~/.vim/bundle/neobundle.vim/

" Required:
call neobundle#begin(expand('~/.vim/bundle/'))

" Let NeoBundle manage NeoBundle
" Required:
NeoBundleFetch 'Shougo/neobundle.vim'

" indentlineの設定
NeoBundle 'Yggdroot/indentLine'
let g:indentLine_concealcursor = 'inc'
let g:indentLine_conceallevel = 2
let g:indentLine_faster = 1

" nerdtreeの設定
NeoBundle 'scrooloose/nerdtree'
nnoremap <silent><C-e> :NERDTreeToggle<CR>

"ES6ハイライト設定
NeoBundleLazy 'othree/yajs.vim', {'autoload':{'filetypes':['javascript']}}
autocmd BufRead,BufNewFile *.es6 setfiletype javascript

call neobundle#end()

" Required:
filetype plugin indent on

" If there are uninstalled bundles found on startup,
" this will conveniently prompt you to install them.
NeoBundleCheck

