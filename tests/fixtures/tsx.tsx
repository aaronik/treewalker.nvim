export function ArticlePage() {
  return (
    <div className="article-page">
      <ArticleView />
      <ArticleComments />
    </div>
  );
}

function ArticleView() {
  const { articlePromise } = useLoaderData<ArticlePageLoaderData>();

  return (
    <Suspense fallback={<Spinner />}>
      <Await resolve={articlePromise} errorElement={<ArticleContentError />}>
        {(articleData) => <ArticleContent article={articleData.article} />}
      </Await>
    </Suspense>
  );
}

type ArticleContentProps = {
  article: SingleArticleResponse['article'];
};

function ArticleContent({ article }: ArticleContentProps) {
  const { title, body, tagList } = article;

  return (
    <>
      <div className="banner">
        <div className="container">
          <h1>{title}</h1>
          <ArticleActionsBlock article={article} />
        </div>
      </div>

      <div className="container page">
        <div className="row article-content">
          <div className="col-md-12">
            <p>{body}</p>
            {tagList.length > 0 && (
              <ul className="tag-list">
                {tagList.map((tag) => (
                  <li key={tag} className="tag-default tag-pill tag-outline">
                    {tag}
                  </li>
                ))}
              </ul>
            )}
          </div>
        </div>

        <hr />

        <div className="article-actions">
          <ArticleActionsBlock article={article} />
        </div>
      </div>
    </>
  );
}
