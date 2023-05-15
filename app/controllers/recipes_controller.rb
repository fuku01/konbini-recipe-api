class RecipesController < ApplicationController
  # ユーザー認証をスキップする
  skip_before_action :authenticate_user, only: [:index, :show, :show_new_recipes]

  # GET /recipes
  # 全てのレシピを作成日の降順で取得し、JSON形式で返す
  def index
    recipes = Recipe.all.order(created_at: :desc)
    render json: recipes
  end

  # GET /new_recipes
  # 新着レシピ２０件を取得し、JSON形式で返す
  def show_new_recipes
    recipes = Recipe.all.order(created_at: :desc).limit(20)
    render json: recipes
  end

  # GET /recipes/1
  # 指定されたIDのレシピを取得し、JSON形式で返す
  def show
    recipe = Recipe.find(params[:id])
    render json: recipe.to_json(include: :tags) # タグ情報も含めてJSON形式で返す
  end

  # GET /my_recipes
  # ログイン中のユーザーの投稿したレシピ情報を取得し、お気に入り登録されている数もカウントした結果を代入する
  def show_my_recipes
    recipes = Recipe.where(user_id: @current_user.id)
                    .select('recipes.*, COUNT(favorites.id) as favorites_count') # favoritesテーブルのidをカウントする（いいねの数を取得）
                    .left_joins(:favorites) # レシピとfavoritesテーブルを結合する（いいねしてないものも含む）
                    .group('recipes.id') # レシピごとにグループ化する
                    .order(created_at: :desc) # 作成日の降順で並び替える
    render json: recipes.as_json(methods: :favorites_count) # レシピ情報にfavorites_countを追加してJSON形式で返す
  end

  # GET /favorite_recipes
  # ログイン中のユーザーのいいねしたレシピ情報を取得し、お気に入り登録されている数もカウントした結果を代入する
  def show_favorite_recipes
    recipes = Recipe.joins(:favorites) # レシピとfavoritesテーブルを結合する（いいねしてるものだけ）
                    .where(favorites: { user_id: @current_user.id }) # favoritesテーブルのuser_idがログイン中のユーザーのIDと一致するレシピを取得する
                    .select('recipes.*, COUNT(favorites.id) as favorites_count') # favoritesテーブルのidをカウントする（いいねの数を取得）
                    .group('recipes.id') # レシピごとにグループ化する
                    .order('favorites.created_at DESC') # favoritesテーブルの作成日の降順で並び替える
    render json: recipes.as_json(methods: :favorites_count) # レシピ情報にfavorites_countを追加してJSON形式で返す
  end

  # POST /recipes
  # 新しいレシピを作成し、JSON形式で返す
  def create
    recipe = Recipe.new(recipe_params)
    recipe.user_id = @current_user.id

    if recipe.save
      render json: recipe, status: :created
    else
      puts recipe.errors.inspect # Add this line to output error messages
      render json: recipe.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /recipes/1
  # 指定されたIDのレシピ情報を更新し、JSON形式で返す
  def update
    recipe = Recipe.find(params[:id])
    if recipe.user_id == @current_user.id
      if recipe.update(recipe_params)
        render json: recipe
      else
        render json: recipe.errors, status: :unprocessable_entity
      end
    else
      render json: { error: 'このレシピの編集権限がありません' }, status: :forbidden
    end
  end

  # DELETE /recipes/1
  # 指定されたIDのレシピを削除する
  def destroy
    recipe = Recipe.find(params[:id])
    if recipe.user_id == @current_user.id
      recipe.destroy
    else
      render json: { error: 'このレシピの削除権限がありません' }, status: :forbidden
    end
  end

  private

  # レシピの情報を受け取る際に、許可されたパラメータのみを受け取るようにする
  # tags_attributes（親要素と子要素を同時に作成・更新するための記述）で、
  # has_many関係にあるtagsの情報を受け取るようにする。
  def recipe_params
    params.require(:recipe).permit(:title, :content, :time, :price, :calorie, :image,
                                   tags_attributes: [:id, :name, :_destroy])
  end
end
