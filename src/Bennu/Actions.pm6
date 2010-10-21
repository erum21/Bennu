class Bennu::Actions;

has @!CLASS-STACK;

method CLASS {
    if @!CLASS-STACK.elems {
        @!CLASS-STACK[*-1]
    }
    else {
        die 'Invalid use of ::?CLASS outside of a class.';
    }
}

use Bennu::AST;
use Bennu::Decl;
use Bennu::MOP;

method ws($/) { }
method vws($/) { }
method unv($/) { }

method unspacey($/) { }
method begid($/) { }
method spacey($/) { }
method nofun($/) { }

method unitstart($/) { }

method comp_unit($/) {
    make Bennu::AST::CompilationUnit.new(statementlist =>
                                         $<statementlist>.ast);
}

method unitstopper($/) { }

method stdstopper($/) {}
method stopper($/) { }

method infixstopper($/) { }

method curlycheck($/) { }

method apostrophe($/) { }

method ident($/) {
    make ~$/;
}

method identifier($/) {
    make ~$/;
}

method longname($/) {
    if $<colonpair>.elems {
        $/.sorry("Adverbs to longnames not yet implemented.");
    }
    make $<name>.ast;
}

method name($/) {
    my @names = $<identifer>.ast;
    for $<morename>.>>.ast -> $name {
        @names.push($name);
    }
    make @names;
}

method morename($/) {
    if $<EXPR>.elems {
        $/.sorry("Indirect names not yet implemented.");
        return;
    }
    make $<identifier>[0].ast;
}

method scope_declarator($/) { }

method scope_declarator:sym<has>($/) {
    my $ast = $<scoped>.ast;
    $ast.scope = 'has';
    make $ast;
}

method package_declarator($/) { }

method package_declarator:sym<class>($/) {
    my $package-def = $<package_def>.ast;
    make Bennu::Decl::Class.new(:name($package-def<name>),
                                :body($package-def<body>),
                                :traits($package-def<traits>));
}

method scoped($/) {
    when $<declarator> :exists {
        make $<declarator>.ast;
    }
    when $<typename>.elems == 1 {
        my $ast = $<multi_declarator>.ast;
        $ast.add-constraint($<typename>[0].ast);
        make $ast;
    }
    default {
        $/.sorry("Non-simple scoped declarations not yet implemented.");
    }
}

method package_def($/) {
    unless $<longname>.elems {
        $/.sorry('Anonymous packages not yet implemented.');
        return;
    }
    if $<signature>.elems {
        $/.sorry('Generic roles not yet implemented.');
        return;
    }
    my $name = $<longname>[0].ast;
    my @traits = $<trait>.>>.ast;
    my $body;
    if $<blockoid>:exists {
        $body = $<blockoid>.ast;
    }
    else {
        $/.sorry("Semicolon form of $*PKGDECL definition not yet implemented.");
        return;
    }

    make {:$name, :@traits, :$body};
}

method declarator($/) {
    when $<variable_declarator> :exists {
        make $<variable_declarator>.ast;
    }
    default {
        $/.sorry("Not all declarators are supported.");
    }
}

method variable_declarator($/) {
    if $<shape>.elems {
        $/.sorry("Shaped variable declarations not yet implemented.");
    }
    if $<post_constraint>.elems {
        $/.sorry("Post constraints on variables not yet implemented.");
    }
    my @traits = $<trait>.map(*.ast);
    make Bennu::Decl::Variable.new(variable => $<variable>.ast,
                                   :@traits);
}

method multi_declarator($/) { }
method multi_declarator:sym<null>($/) {
    make $<declarator>.ast;
}

method routine_declarator($/) { }

method routine_declarator:sym<method>($/) {
    make $<method_def>.ast;
}

method method_def($/) {
    if $<sigil>:exists {
        $/.sorry('Sigil-dot-postcirumfix method definitions not yet implemented.');
        return;
    }
    if ~$<type> {
        my $type = $<type> eq '!' ?? 'Private' !! 'Meta';
        $/.sorry("$type method definitions not yet implemented.");
        return;
    }
    if $<multisig>.elems > 1 {
        $/.sorry('Multiple multisigs in a method definition not yet implemented.');
        return;
    }
    if $*SCOPE eq 'augment'|'supersede'|'state' {
        $/.sorry("Illogical scope $scope for method");
        return;
    }

    my $name = $<longname>.ast;
    my $sig = $<multisig>[0].?ast // Bennu::Decl::Method.default-signature;
    my @traits = $<trait>.>>.ast;
    my $body = $<blockoid>.ast;
    make Bennu::Decl::Method.new(:$name, :$sig, :$body, :@traits);
}

method trait($/) {
    when $<trait_mod>:exists {
        make $<trait_mod>.ast;
    }
    when $<colonpair>:exists {
        make $<colonpair>.ast;
    }
}

method trait_mod($/) { }

method trait_mod:sym<is>($/) {
    if $<circumfix>.elems {
        $/.sorry("Postcircumfixes in traits not yet implemented.");
        return;
    }
    my $name = $<longname>.ast;
    if $name[0] eq 'bennu' {
        given $name[1] {
            when 'll-class' {
                make Bennu::Decl::LLClassTrait.new;
            }
            default {
                $/.sorry("Unrecognized bennu::$_ trait.");
            }
        }
    } else {
        $/.sorry("Non-bootstrap traits not yet implemented.");
    }
}

method variable($/) {
    my $ast;
    if $<desigilname> :exists {
        $ast = Bennu::AST::Lexical.new(:desigilname($<desigilname>.ast),
                                       :sigil($<sigil>.ast));
        $ast.twigil = $<twigil>[0].ast
          if $<twigil>[0]:exists;
    }
    else {
        $/.sorry("Non-simple variables not yet implemented.");
    }

    if $<postcircumfix>.elems {
        my $post = $<postcircumfix>[0].ast;
        $post.args.unshift($ast);
        $ast = $post;
    }
    make $ast;
}

method desigilname($/) {
    when $<variable> :exists {
        $/.sorry("Contextualizing sigils not yet implemented.");
    }
    default {
        make $<longname>.ast;
    }
}

method sigil($/) {
    make ~$/;
}
method sigil:sym<$>($/) { }

method twigil($/) {
    make ~$/;
}
method twigil:sym<.>($/) { }
method twigil:sym<!>($/) { }

method typename($/) {
    my $type;
    if $<identifier> :exists {
        # ::?CLASS
        $/.sorry('::?CLASS not yet implemented.');
    }
    else {
        $type = $<longname>.ast;
    }
    if +$<typename> {
        # typename of typename
        $/.sorry('infix:<of> not yet implemented.');
    }
    else {
        if +$<param> {
            $/.sorry('Parameterized types not yet implemented.');
        }
        if +$<whence> {
            $/.sorry('WHENCE not yet implemented.');
        }
        else {
            make $type;
        }
    }
}

method termish($/) { }

method EXPR($/) { }

method arglist($/) {
    given $<EXPR>.ast {
        when not *.defined {
            make [];
        }
        when Bennu::AST::Parcel {
            make $_;
        }
        default {
            make [ $_ ];
        }
    }
}

method args($/) {
    when $<moreargs> :exists {
        $/.sorry("Bennu can't handle listop(...): ... yet.");
    }
    when $<semiarglist> :exists {
        make $<semiarglist>.ast;
    }
    when $<arglist>.elems {
        make $<arglist>[0].ast;
    }
    default {
        make [];
    }
}

method circumfix($/) { }

method circumfix:sym<( )>($/) {
    my @children = $<semilist>.ast.grep: *.defined;
    if @children == 1 {
        make @children[0];
    }
    else {
        $/.sorry('Parcels with multiple elements not yet implemented.');
    }
}

method POST($/) {
    if $<postfix_prefix_meta_operator>.elems {
        $/.sorry('postfix_prefix_meta_operator not yet implemented.');
        return;
    }
    if $<dotty> :exists {
        make $<dotty>.ast;
    }
    elsif $<privop> :exists {
       make $<privop>.ast;
    }
    else {
        make $<postop>.ast;
    } 
}

method POSTFIX($/) {
    my $ast;
    if $<dotty> :exists {
        $ast = $<dotty>.ast;
    }
    else {
        $/.sorry('Non-dotty postfixes not yet implemented.');
        return;
    }
    $ast.unshift($<arg>.ast);
    make $ast;
}

method infix($/) {
    make Bennu::AST::Lexical.new(desigilname => 'infix:<' ~ $/<sym> ~ '>',
                                 sigil => '&');
}

method infix:sym<+>($/) { }

method term($/) { }

method term:sym<identifier>($/) {
    my $ident = $<identifier>.ast;
    when $/.is_name($<identifier>.Str) {
        make Bennu::AST::Lexical.new(desigilname => $ident);
    }
    default {
        my $args = $<args>.ast;
        make Bennu::AST::Call.new(function =>
                                  Bennu::AST::Lexical.new(desigilname => $ident,
                                                         sigil => '&'),
                                  args => $args);
    }
}

method term:sym<package_declarator>($/) {
    make $<package_declarator>.ast;
}

method term:sym<scope_declarator>($/) {
    make $<scope_declarator>.ast;
}

method term:sym<routine_declarator($/) {
    make $<routine_declarator>.ast;
}

method term:sym<value>($/) {
    make $<value>.ast;
}

method term:sym<variable>($/) {
    make $<variable>.ast;
}

method infixish($/) {
    if $<colonpair> :exists {
        make $<colonpair>.ast
    }
    elsif $<infix_postfix_meta_operator>.elems {
        make $<infix_postfix_meta_operator>.ast;
    } else {
        make $<infix>.ast;
    }
}

method INFIX($/) {
    my $func = $/.ast;
    make Bennu::AST::Call.new(function => $func,
                              args => [ $<left>.ast,
                                        $<right>.ast]);
}

method dotty($/) { }
method dotty:sym<.>($/) {
    make $<dottyop>.ast;
}

method dottyop($/) {
    when $<methodop> :exists {
        make $<methodop>.ast;
    }
    when $<colonpair> :exists {
        make $<colonpair>.ast;
    }
    when $<postop> :exists {
        make $<postop>.ast;
    }
}

method methodop($/) {
    my $ast;
    if $<longname> :exists {
        $ast = Bennu::AST::MethodCall.new(name => $<longname>.ast);
    }
    elsif $<variable> :exists {
        $ast = Bennu::AST::Call.new(function => $<variable>.ast);
    }
    elsif $<quote> :exists {
        $ast = Bennu::AST::IndirectMethodCall.new(name => $<quote>.ast);
    }

    if $<arglist>.elems {
        $ast.args = $<arglist>[0].ast;
    }
    elsif $<args>.elems {
        $ast.$args = $<args>[0].ast;
    }

    make $ast;
}

method value:sym<number>($/) {
    make $<number>.ast;
}

method decint($/) {
    make Bennu::AST::Integer.new(value => $/.Str.subst(/_/, '').Int);
}

method integer($/) {
    when $<binint> :exists {
        make $<binint>.ast;
    }
    when $<octint> :exists {
        make $<octint>.ast;
    }
    when $<hexint> :exists {
        make $<hexint>.ast;
    }
    when $<decint> :exists {
        make $<decint>.ast;
    }
}

method number($/) {
    given ~$/ {
        when $<integer> :exists {
            make $<integer>.ast;
        }
        when $<dec_number> :exists {
            make $<dec_number>.ast;
        }
        when $<rad_number> :exists {
            make $<rad_number>.ast;
        }
        when 'NaN' {
            make Bennu::AST::NaN.new;
        }
        when 'Inf' {
            make Bennu::AST::Inf.new;
        }
    }
}

method statementlist($/) {
    my $ast = Bennu::AST::StatementList.new;
    for @($<statement>) -> $statement {
        $ast.push($statement.ast);
    }
    make $ast;
}
    
method semilist($/) {
    make $<statement>.>>.ast;
}

method statement($/) {
    when $<label> :exists {
        make Bennu::AST::Labelled.new(statement => $<statement>.ast);
    }
    when $<statement_control> :exists {
        make $<statement_control>.ast;
    }
    when $<EXPR> :exists {
        when $<statement_mod_loop> {
            my $loop = $<statement_mod_loop>[0].ast;
            $loop.body = $<EXPR>.ast;
            make $loop;
        }
        when $<statement_mod_cond> {
            my $cond = $<statement_mod_cond>[0].ast;
            $cond.body = $<EXPR>.ast;
            make $cond;
        }
        default {
            make $<EXPR>.ast;
        }
    }
}

method statement_control($/) { }

method statement_control:sym<if>($/) {
    my @conditions = $<xblock><EXPR>.ast;
    my @blocks = $<xblock><pblock>.ast;
    for $<elsif>.list -> $xblock {
        @conditions.push($xblock<EXPR>.ast);
        @blocks.push($xblock<pblock>.ast);
    }

    my $ast = Bennu::AST::Conditional.new(:@conditions, :@blocks);
    $ast.otherwise = $<else>[0].ast
        if $<else>.elems;
    make $ast; 
}

method blockoid($/) {
    if $<statementlist> :exists {
        make Bennu::AST::Block.new(statementlist => $<statementlist>.ast);
    }
    else {
        $/.sorry('{YOU_ARE_HERE} not yet implemented... seriously.');
    }
}

method pblock($/) {
    if $<lambda> :exists {
        $/.sorry('Lambdas not yet implemented.');
    }
    else {
        make Bennu::AST::Block.new(body => $<blockoid>.ast);
    }
}

method xblock($/) { }

method eat_terminator($/) { }

method terminator($/) { }
method terminator:sym<;>($/) { }
method terimnator:sym<)>($/) { }
