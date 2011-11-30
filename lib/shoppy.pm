package shoppy;
use Dancer ':syntax';
use Dancer::Plugin::Auth::Twitter;
use Dancer::Plugin::Database;

use Net::Amazon;
use Encode;

our $VERSION = '0.1';

# Twitter初期化
auth_twitter_init();

# フィルタ処理
before sub {
    # 以下のURLの場合ログイン処理へリダイレクト
    if (    not request->path =~ /\/login/
        and not request->path =~ /\/auth\/twitter\/callback/
        and not request->path =~ /\/forward_twitter/
        and not request->path =~ /~\/detail/
        and not session('twitter_user') )
    {
        # ログイン画面へリダイレクト
        redirect uri_for('/login');
    }
};

# ログイン画面
get '/login' => sub {
    template 'login';
};

# TwitterのOAuth画面へリダイレクト
get '/forward_twitter' => sub {
    redirect auth_twitter_authenticate_url;
};

# HOME画面
get '/' => sub {
    # 一覧SQL準備
    my $sth = database->prepare(
        'select * from comments order by id desc limit 10',
    );
    # 一覧取得実行
    $sth->execute();

    # データを取り出してテンプレートへ渡す
    template 'index',  { list => $sth->fetchall_arrayref({}) };
};

# 詳細画面
get '/detail/:asin' => sub {
    # 受け取ったasinを元にデータを取得
    my $sth = database->prepare(
        'select * from comments where asin = ? order by id desc limit 10',
    );
    $sth->execute(params->{asin});

    template 'detail',  { list => $sth->fetchall_arrayref({}) };
};

# 検索画面
post '/search' => sub {
    # リクエストパラメータを取り出す
    my $word = params->{word};

    # Amazonモジュール生成
    my $conf = config->{Amazon};
    my $ua = Net::Amazon->new(
        associate_tag => $conf->{associate_tag},
        token         => $conf->{token},
        secret_key    => $conf->{secret_key},
        'locale'      => 'jp',
        ResponseGroup => 'Medium',
    );

    my %tp = ();
    $tp{word} = $word;
    # Amazonへリクエスト
    my $res = $ua->search(keyword => $word);
    # 成功したらテンプレートに渡すパラメータに商品リスト情報を格納
    if ( $res->is_success() ) {
        $tp{items} = $res->{xmlref}->{Items};
    }

    # 受け取った商品情報の日本語文字列がUTF8なのでUnicodeに変換
    for my $item (@{$tp{items}}) {
        $item->{ItemAttributes}->{Title} = 
        decode('utf8', $item->{ItemAttributes}->{Title});
    }
    template 'search', \%tp;
};

# ツイート & DB保存処理
post '/publish' => sub {

    # aisnを受け取る
    my $asin = params->{asin};
    # Amazonモジュール生成
    my $conf = config->{Amazon};
    my $ua = Net::Amazon->new(
        associate_tag => $conf->{associate_tag},
        token         => $conf->{token},
        secret_key    => $conf->{secret_key},
        'locale'      => 'jp',
        ResponseGroup => 'Medium',
    );

    # asinで検索
    my $res = $ua->search(asin => $asin);
    # 失敗したらHOMEへリダイレクト
    unless ($res->is_success()) {
        return redirect uri_for('/');
    }
    # aisnで取得した商品情報を取り出す
    my $item = $res->{xmlref}->{Items}->[0];
    # DB保存
    database->quick_insert('comments', {
        asin => $asin,
        title => decode('utf8', $item->{ItemAttributes}->{Title}),
        url => $item->{DetailPageURL},
        price => $item->{ItemAttributes}->{ListPrice}->{Amount},
        image_url => $item->{MediumImage}->{URL},
        comment => params->{comment},
    });

    # ツイート文字列生成
    my $tweet = params->{comment} . ' ' . uri_for('/detail/' . $asin);
    # Twitterモジュールにアクセストークンなどユーザのキーをセット
    twitter->access_token(session('twitter_user')->{access_token});
    twitter->access_token_secret(session('twitter_user')->{access_token_secret});

    # twitter投稿
    twitter->update($tweet);

    # HOMEへリダイレクト
    return redirect uri_for('/');

};

# OAuth失敗時の処理
get '/fail' => sub {
    redirect uri_for('/');
};

true;
