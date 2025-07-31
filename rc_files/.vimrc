" Author: Sarat Sreepathi (admin@sarats.com)
" Author: Vamsi Sripathi (admin@vamsis.com)
" $LastChangedBy: vamsi $
" $LastChangedDate: 2011-10-15 16:00:48 -0700 (Sat, 15 Oct 2011) $
" $LastChangedRevision: 74 $

:set autowrite
:set number
:syntax on    " Enable syntax highlighting

" Enable syntax highlighting for *.fxx
au BufNewFile,BufRead *.fxx set filetype=fortran
au BufNewFile,BufRead *.axx set filetype=asm
au BufNewFile,BufRead make_blas_* set filetype=make
au BufNewFile,BufRead make_matmul* set filetype=make

" Indentation options
:set shiftwidth=2  " Control how many columns text is indented with the reindent operations (<< and >>) and automatic C-style indentation
:set tabstop=2     " Tell vim how many columns a tab counts for.
:set softtabstop=2 " To control how many columns vim uses when you hit Tab in insert mode.
" :set noexpandtab   " Already default but just making sure.
:set expandtab   
:set cindent
" :set cinoptions="(0,u0,U0 "
" :set cinoptions=(0 "
:set cinoptions+=(0


" Search options
:set hlsearch
:set incsearch
:set ignorecase
:set smartcase


:set nocompatible   " Make sure you are not running in legacy mode
:filetype plugin on " Already default but making sure


:runtime! ftplugin/man.vim   " Enables to view man pages in a window (:Man malloc)
let g:DoxygenToolkit_authorName="Vamsi Sripathi"  " Change this accordingly
" let g:DoxygenToolkit_briefTag_funcName="yes"
let g:DoxygenToolkit_briefTag_pre="@brief "
let g:DoxygenToolkit_paramTag_pre="@param "
let g:DoxygenToolkit_returnTag="@returns "
let g:DoxygenToolkit_blockHeader="--------------------------------------------------------------------------"
let g:DoxygenToolkit_blockFooter="--------------------------------------------------------------------------"
let g:DoxygenToolkit_licenseTag="--------------------------------------------------------------------------\<enter>"
let g:DoxygenToolkit_licenseTag=g:DoxygenToolkit_licenseTag . "INTEL CONFIDENTIAL\<enter>"
let g:DoxygenToolkit_licenseTag=g:DoxygenToolkit_licenseTag . "Copyright(C) 2015 Intel Corporation. All Rights Reserved.\<enter>"
let g:DoxygenToolkit_licenseTag=g:DoxygenToolkit_licenseTag . "The source code contained  or  described herein and all documents related to\<enter>"
let g:DoxygenToolkit_licenseTag=g:DoxygenToolkit_licenseTag . "the source code (\"Material\") are owned by Intel Corporation or its suppliers\<enter>"
let g:DoxygenToolkit_licenseTag=g:DoxygenToolkit_licenseTag . "or licensors.  Title to the  Material remains with  Intel Corporation or its\<enter>"
let g:DoxygenToolkit_licenseTag=g:DoxygenToolkit_licenseTag . "suppliers and licensors. The Material contains trade secrets and proprietary\<enter>"
let g:DoxygenToolkit_licenseTag=g:DoxygenToolkit_licenseTag . "and  confidential  information of  Intel or its suppliers and licensors. The\<enter>"
let g:DoxygenToolkit_licenseTag=g:DoxygenToolkit_licenseTag . "Material  is  protected  by  worldwide  copyright  and trade secret laws and\<enter>"
let g:DoxygenToolkit_licenseTag=g:DoxygenToolkit_licenseTag . "treaty  provisions. No part of the Material may be used, copied, reproduced,\<enter>"
let g:DoxygenToolkit_licenseTag=g:DoxygenToolkit_licenseTag . "modified, published, uploaded, posted, transmitted, distributed or disclosed\<enter>"
let g:DoxygenToolkit_licenseTag=g:DoxygenToolkit_licenseTag . "in any way without Intel's prior express written permission.\<enter>"
let g:DoxygenToolkit_licenseTag=g:DoxygenToolkit_licenseTag . "No license  under any  patent, copyright, trade secret or other intellectual\<enter>"
let g:DoxygenToolkit_licenseTag=g:DoxygenToolkit_licenseTag . "property right is granted to or conferred upon you by disclosure or delivery\<enter>"
let g:DoxygenToolkit_licenseTag=g:DoxygenToolkit_licenseTag . "of the Materials,  either expressly, by implication, inducement, estoppel or\<enter>"
let g:DoxygenToolkit_licenseTag=g:DoxygenToolkit_licenseTag . "otherwise.  Any  license  under  such  intellectual property  rights must be\<enter>"
let g:DoxygenToolkit_licenseTag=g:DoxygenToolkit_licenseTag . "express and approved by Intel in writing.\<enter>"
let g:DoxygenToolkit_licenseTag=g:DoxygenToolkit_licenseTag . "--------------------------------------------------------------------------"


" Press space to clear search highlighting and any message already displayed.
" VERY USEFUL for getting rid of annoying message when a search term is not found
nnoremap <silent> <Space> :silent noh<Bar>echo<CR>


set laststatus=2 " always show the status line , Note:you can use ctrl-g to show status in case it's not visible
set statusline=%F%m%r%h%w\ [%LL][%{&ff}]%y\ [%p%%]\ [%l\ L,%v]
" default the statusline to White when entering Vim
hi statusline ctermbg=White ctermfg=DarkGray 
au InsertLeave * hi statusline ctermbg=White ctermfg=DarkGray
au InsertEnter * hi statusline ctermbg=DarkRed ctermfg=DarkGray

" :hi CursorLine cterm=NONE ctermbg=darkgrey ctermfg=white guibg=darkred guifg=white
" set cursorline " highlight current line
" set ruler " Always show current positions along the bottom

" :highlight Comment ctermfg=green
:highlight Comment ctermfg=Magenta
 
nmap <F12> 1G=G      " Shortcut to auto indent entire file
imap <F12> <ESC>1G=Ga

" Map F8 to split window vertically and open the file under the cursor
:map <F8> W:vertical wincmd f<CR>

" Split the window vertically with new windows on the right side
set splitright
set foldmethod=syntax
set foldlevel=10
set nofoldenable     "dont fold by default
set foldlevel=1         

" For code folding
" use zM to close all folds, zR to open all folds
" za just to toggle the status (open/closed) of current fold
inoremap <F9> <C-O>za
nnoremap <F9> za
onoremap <F9> <C-C>za
vnoremap <F9> zf

" Ignore .o files when doing filename completion etc
set wildignore=*.o

" Set path to your ctags file. 
set tags=./tags

" MKL targeted variables
let mkl_tags=$MKL_TAGS
if !empty(mkl_tags)
   set tags=${MKL_CTAGS},./tags
   set path+=${MKL_SRC}/blas/include
   set path+=${ICL_LIB_PATH}/../include/
endif

" Caffe targeted variables
let caffe_tags=$CAFFE_TAGS
if !empty(caffe_tags)
   set tags=${CAFFE_CTAGS},${MKL_CTAGS},./tags
   set path+=${CAFFE_SRC}/include
   set path+=${CAFFE_SRC}/src
   set path+=${CAFFE_SRC}/tools
   set path+=${ICL_LIB_PATH}/../include/
endif

" Eigen targeted variables
let eigen_tags=$EIGEN_TAGS
if !empty(eigen_tags)
   set tags=${EIGEN_CTAGS},${MKL_CTAGS},./tags
   set path+=${EIGEN_SRC}/include
   set path+=${EIGEN_SRC}/src
   set path+=${EIGEN_SRC}/tools
   set path+=${ICL_LIB_PATH}/../include/
endif

highlight! link DiffText MatchParen
" ****************************************************************************************
" TIPS
" ****************************************************************************************
" Use * to forward search for current word, # for reverse search
" The corresponding g* and g# commands search for anything containing the
" correct word not just exact word
" 
" TAG NAVIGATION
" You can use the 'tselect' ex command to list all the tag matches. For
" example, the command ':tselect func1' will list all the locations where func1
" is defined. You can then enter the number of a tag match to jump to that
" location.
" 
" You can position the cursor over the tag name and press g] to get a list of
" matching tags. 
"
" FOLDING
" The command zc will close a fold (if the cursor is in an open fold), and zo
" will open a fold (if the cursor is in a closed fold). It's easier to just
" use za which will toggle the current fold (close it if it was open, or open
" it if it was closed). 
" JUST REMEMBER za that opens/closes the fold
"
" STATUS LINE EXPLANATION
" set statusline=%F%m%r%h%w[%L][%{&ff}]%y[%p%%][%l,%v]
	"              | | | | |  |   |      |  |     |    |
	"              | | | | |  |   |      |  |     |    + current
	"              | | | | |  |   |      |  |     |       column
	"              | | | | |  |   |      |  |     +-- current line
	"              | | | | |  |   |      |  +-- current % into file
	"              | | | | |  |   |      +-- current syntax in
	"              | | | | |  |   |          square brackets
	"              | | | | |  |   +-- current fileformat
	"              | | | | |  +-- number of lines
	"              | | | | +-- preview flag in square brackets
	"
	"              | | | +-- help flag in square brackets
	"              | | +-- readonly flag in square brackets
	"              | +-- modified flag in square brackets
	"              +-- full path to file in the buffer
